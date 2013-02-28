# encoding: UTF-8
# Wrapper for worklog entries, containing
# WorkLog, WikiPage and ProjectFile types linking to
# the respective models of those types
#

require 'to_id'

class EventLog < ActiveRecord::Base
  belongs_to :target, :polymorphic => true
  belongs_to :user
  belongs_to :company
  belongs_to :project

  TASK_CREATED       = 1
  TASK_COMPLETED     = 2
  TASK_REVERTED      = 3
  TASK_DELETED       = 4
  TASK_MODIFIED      = 5
  TASK_COMMENT       = 6
  TASK_WORK_ADDED    = 7
  TASK_ASSIGNED      = 8
  TASK_ARCHIVED      = 9
  TASK_RESTORED      = 16

  PAGE_CREATED       = 10
  PAGE_DELETED       = 11
  PAGE_RENAMED       = 12
  PAGE_MODIFIED      = 13

  WIKI_CREATED       = 14
  WIKI_MODIFIED      = 15

  FILE_UPLOADED      = 20
  FILE_DELETED       = 21

  ACCESS_GRANTED     = 30
  ACCESS_REVOKED     = 31

  SCM_COMMIT         = 40

  PROJECT_COMPLETED   = 50
  MILESTONE_COMPLETED = 51
  PROJECT_REVERTED    = 52
  MILESTONE_REVERTED  = 53

  RESOURCE_PASSWORD_REQUESTED = 70
  RESOURCE_CHANGE = 71

  scope :by_company,  ->(companies) { where(company_id: companies) }
  scope :by_project,  ->(projects)  { where('event_logs.project_id IN (?) OR event_logs.project_id IS NULL', ToIDs(projects)) }
  scope :accessed_by, ->(user) {
     by_company(user.company)
    .by_project(user.project_ids)
    .where(%q{
      ( event_logs.target_type != 'WorkLog' OR event_logs.target_type IS NULL ) OR
      ( event_logs.target_id IN
        ( SELECT work_logs.id
          FROM work_logs JOIN project_permissions ON work_logs.project_id = project_permissions.project_id AND
                                                     project_permissions.user_id = :user_id
          WHERE work_logs.id = event_logs.target_id AND
                work_logs.access_level_id <= :access_level_id AND
                ( project_permissions.can_see_unwatched = :unwatched OR
                  :user_id IN ( SELECT task_users.user_id
                                FROM task_users
                                WHERE task_users.task_id = work_logs.task_id )
                )
        )
      )
    }, {user_id: user.id, access_level_id: user.access_level_id, unwatched: true})
  }

  def started_at
    self.created_at
  end

  def EventLog.event_logs_for_timeline(current_user, params)
    filter = ""
    tz = TZInfo::Timezone.new(current_user.time_zone)
    filter << " AND event_logs.event_type = #{EventLog::WIKI_CREATED}" if params[:filter_status].to_i == EventLog::WIKI_CREATED
    filter << " AND event_logs.event_type IN (#{EventLog::WIKI_CREATED},#{EventLog::WIKI_MODIFIED})" if params[:filter_status].to_i == EventLog::WIKI_MODIFIED
    filter << " AND event_logs.event_type = #{ EventLog::RESOURCE_PASSWORD_REQUESTED }" if params[:filter_status].to_i == EventLog::RESOURCE_PASSWORD_REQUESTED
    filter << " AND event_logs.event_type = #{EventLog::TASK_CREATED}" if params[:filter_status].to_i == EventLog::TASK_CREATED
    filter << " AND event_logs.event_type IN (#{EventLog::TASK_REVERTED},#{EventLog::TASK_COMPLETED})" if params[:filter_status].to_i == EventLog::TASK_REVERTED
    filter << " AND event_logs.event_type = #{EventLog::TASK_COMPLETED}" if params[:filter_status].to_i == EventLog::TASK_COMPLETED
    filter << " AND event_logs.event_type = #{EventLog::TASK_COMMENT}" if params[:filter_status].to_i == EventLog::TASK_COMMENT
    filter << " AND event_logs.event_type = #{EventLog::TASK_MODIFIED}" if params[:filter_status].to_i == EventLog::TASK_MODIFIED
    filter << " AND event_logs.event_type = #{EventLog::TASK_WORK_ADDED}" if params[:filter_status].to_i == EventLog::TASK_WORK_ADDED

    if params[:filter_date].to_i == 1
      filter << " AND event_logs.created_at < '#{tz.now.to_s(:db)}' "
    elsif params[:filter_date].to_i == 2
      start_date = tz.now
      if params[:start_date] && params[:start_date].length > 1
        begin
          start_date = DateTime.strptime(params[:start_date], current_user.date_format).to_time
        rescue
          flash['error'] ||= _("Invalid start date")
        end

        start_date = tz.local_to_utc(start_date.midnight)
      end

      filter << " AND event_logs.created_at < '#{start_date.to_s(:db)}' "
    end

    filter = " AND event_logs.project_id = #{params[:filter_project].to_i}" + filter if params[:filter_project].to_i > 0

    EventLog.accessed_by(current_user).includes(:user).order("event_logs.created_at desc").where("TRUE #{filter}").limit(params[:limit] || 30).offset(params[:offset] || 0)
  end

end


# == Schema Information
#
# Table name: event_logs
#
#  id          :integer(4)      not null, primary key
#  company_id  :integer(4)
#  project_id  :integer(4)
#  user_id     :integer(4)
#  event_type  :integer(4)
#  target_type :string(255)
#  target_id   :integer(4)
#  title       :string(255)
#  body        :text
#  created_at  :datetime
#  updated_at  :datetime
#  user        :string(255)
#
# Indexes
#
#  index_event_logs_on_company_id_and_project_id  (company_id,project_id)
#  index_event_logs_on_target_id_and_target_type  (target_id,target_type)
#  fk_event_logs_user_id                          (user_id)
#

