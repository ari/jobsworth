# encoding: UTF-8
# Wrapper for worklog entries, containing
# WorkLog, WikiPage and ProjectFile types linking to
# the respective models of those types
#

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

  scope :accessed_by, lambda { |user|
    where("event_logs.company_id = ? AND (event_logs.project_id IN (?) OR event_logs.project_id IS NULL) AND if(target_type = 'WorkLog', (event_logs.target_id IN (select work_logs.id from work_logs join project_permissions on work_logs.project_id = project_permissions.project_id and project_permissions.user_id = ? where work_logs.id = event_logs.target_id and work_logs.access_level_id <= ? and (project_permissions.can_see_unwatched = ? or ? in (select task_users.user_id from task_users where task_users.task_id = work_logs.task_id)))) , true) ", user.company_id, user.project_ids, user.id, user.access_level_id, true, user.id)
  }

  def started_at
    self.created_at
  end

  def EventLog.event_logs_for_timeline(current_user, params)
    filter = ""
    tz = TZInfo::Timezone.new(current_user.time_zone)
    filter << " AND event_logs.user_id = #{params[:filter_user].to_i}" if params[:filter_user].to_i > 0
    filter << " AND event_logs.event_type = #{EventLog::WIKI_CREATED}" if params[:filter_status].to_i == EventLog::WIKI_CREATED
    filter << " AND event_logs.event_type IN (#{EventLog::WIKI_CREATED},#{EventLog::WIKI_MODIFIED})" if params[:filter_status].to_i == EventLog::WIKI_MODIFIED
    filter << " AND event_logs.event_type = #{ EventLog::RESOURCE_PASSWORD_REQUESTED }" if params[:filter_status].to_i == EventLog::RESOURCE_PASSWORD_REQUESTED
    filter << " AND event_logs.event_type = #{EventLog::TASK_CREATED}" if params[:filter_status].to_i == EventLog::TASK_CREATED
    filter << " AND event_logs.event_type IN (#{EventLog::TASK_CREATED},#{EventLog::TASK_REVERTED},#{EventLog::TASK_COMPLETED})" if params[:filter_status].to_i == EventLog::TASK_REVERTED
    filter << " AND event_logs.event_type = #{EventLog::TASK_COMPLETED}" if params[:filter_status].to_i == EventLog::TASK_COMPLETED
    filter << " AND (event_logs.event_type = #{EventLog::TASK_COMMENT} OR work_logs.comment = 1)" if params[:filter_status].to_i == EventLog::TASK_COMMENT
    filter << " AND event_logs.event_type = #{EventLog::TASK_MODIFIED}" if params[:filter_status].to_i == EventLog::TASK_MODIFIED
    filter << " AND event_logs.event_type = #{EventLog::TASK_WORK_ADDED}" if params[:filter_status].to_i == EventLog::TASK_WORK_ADDED

    if  (params[:filter_date].to_i > 0) and (params[:filter_date].to_i < 7)
      name = [:'This week', :'Last week', :'This month', :'Last month', :'This year', :'Last year'][params[:filter_date].to_i-1]
      filter << " AND event_logs.created_at > '#{tz.utc_to_local(TimeRange.start_time(name)).to_s(:db)}' AND event_logs.created_at < '#{tz.utc_to_local(TimeRange.end_time(name)).to_s(:db)}'"
    elsif params[:filter_date].to_i == 7
      start_date = tz.now
      end_date = tz.now
      if params[:start_date] && params[:start_date].length > 1
        begin
          start_date = DateTime.strptime( params[:start_date], current_user.date_format ).to_time
        rescue
          flash['error'] ||= _("Invalid start date")
        end

        start_date = tz.local_to_utc(start_date.midnight)
      end

      if params[:stop_date] && params[:stop_date].length > 1
        begin
          end_date = DateTime.strptime( params[:stop_date], current_user.date_format ).to_time
        rescue
          flash['error'] ||= _("Invalid end date")
        end

        end_date = tz.local_to_utc((end_date + 1.day).midnight)
      end

      filter << " AND event_logs.created_at > '#{start_date.to_s(:db)}' AND event_logs.created_at < '#{end_date.to_s(:db)}'"
    end

    filter = " AND event_logs.project_id = #{params[:filter_project].to_i}" + filter if params[:filter_project].to_i > 0

    EventLog.accessed_by(current_user).includes(:user).order("event_logs.created_at desc").where("TRUE #{filter}").paginate(:per_page => 100, :page => params[:page])
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

