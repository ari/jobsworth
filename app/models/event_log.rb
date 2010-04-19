# Wrapper for worklog entries, containing
# WorkLog, WikiPage, ProjectFile, and Post types linking to
# the respective models of those types
#

class EventLog < ActiveRecord::Base
  belongs_to :target, :polymorphic => true
  belongs_to :user
  belongs_to :company

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

  FORUM_NEW_POST      = 60

  RESOURCE_PASSWORD_REQUESTED = 70
  RESOURCE_CHANGE = 71

  named_scope :accessed_by, lambda { |user|
    { :conditions => ["company_id = ? AND (event_logs.project_id IN ( #{user.project_ids_for_sql} ) OR event_logs.project_id IS NULL) AND if(target_type='WorkLog', (select id from work_logs where work_logs.id=event_logs.target_id and work_logs.access_level_id <= ?) , true) ",
                      user.company_id, user.access_level_id]
    }
  }
  def started_at
    self.created_at
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

