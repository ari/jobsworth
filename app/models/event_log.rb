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

  scope :by_company,  ->(companies) { where(company_id: ToIDs(companies)) }
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

  def self.event_logs_for_timeline(current_user, params)
    tz = TZInfo::Timezone.new(current_user.time_zone)
    now = tz.now

    filter_project = params[:filter_project].to_i
    filter_user    = params[:filter_user].to_i
    filter_status  = params[:filter_status].to_i
    filter_date    = params[:filter_date].to_i

    filter = case filter_status
             when WIKI_CREATED
               " AND event_logs.event_type = #{WIKI_CREATED}"
             when WIKI_MODIFIED
               " AND event_logs.event_type IN (#{[WIKI_CREATED, WIKI_MODIFIED].join(',')})"
             when RESOURCE_PASSWORD_REQUESTED
               " AND event_logs.event_type = #{RESOURCE_PASSWORD_REQUESTED }"
             when TASK_CREATED
               " AND event_logs.event_type = #{TASK_CREATED}"
             when TASK_REVERTED
               " AND event_logs.event_type IN (#{[TASK_REVERTED, TASK_COMPLETED].join(',')})"
             when TASK_COMPLETED
               " AND event_logs.event_type = #{TASK_COMPLETED}"
             when TASK_COMMENT
               " AND event_logs.event_type = #{TASK_COMMENT}"
             when TASK_MODIFIED
               " AND event_logs.event_type = #{TASK_MODIFIED}"
             when TASK_WORK_ADDED
               " AND event_logs.event_type = #{TASK_WORK_ADDED}"
             else
               ''
             end

    case filter_date
    when 1
      filter << " AND event_logs.created_at < '#{now.to_s(:db)}' "
    when 2
      start_date = DateTime.strptime(params[:start_date], current_user.date_format).to_time rescue now
      start_date = tz.local_to_utc start_date.midnight

      filter << " AND event_logs.created_at < '#{start_date.to_s(:db)}' "
    end

    filter << " AND event_logs.project_id = #{filter_project}" if filter_project.to_i > 0

    accessed_by(current_user).includes(:user)
                             .order("event_logs.created_at desc")
                             .where("TRUE #{filter}")
                             .limit(params[:limit] || 30)
                             .offset(params[:offset] || 0)
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

