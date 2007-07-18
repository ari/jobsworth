class WorkLog < ActiveRecord::Base

  acts_as_ferret :fields => ['body', 'company_id', 'project_id']

  belongs_to :user
  belongs_to :company
  belongs_to :project
  belongs_to :customer
  belongs_to :task
  belongs_to :scm_changeset

  has_one    :ical_entry

  TASK_CREATED       = 1
  TASK_COMPLETED     = 2
  TASK_REVERTED      = 3
  TASK_DELETED       = 4
  TASK_MODIFIED      = 5
  TASK_COMMENT       = 6
  TASK_WORK_ADDED    = 7
  TASK_ASSIGNED      = 8
  TASK_ARCHIVED      = 9
  TASK_RESTORED      = 14


  PAGE_CREATED       = 10
  PAGE_DELETED       = 11
  PAGE_RENAMED       = 12
  PAGE_MODIFIED      = 13

  FILE_UPLOADED      = 20
  FILE_DELETED       = 21

  ACCESS_GRANTED     = 30
  ACCESS_REVOKED     = 31

  SCM_COMMIT         = 40

  PROJECT_COMPLETED  = 50
  MILESTONE_COMPLETED = 51
  PROJECT_REVERTED   = 52
  MILESTONE_REVERTED = 53

  after_save { |r|
    r.ical_entry.destroy if r.ical_entry
  }

  def self.full_text_search(q, options = {})
    return nil if q.nil? or q==""
    default_options = {:limit => 10, :page => 1}
    options = default_options.merge options
    options[:offset] = options[:limit] * (options.delete(:page).to_i-1)
    results = WorkLog.find_by_contents(q, options)
    return [results.total_hits, results]
  end

end
