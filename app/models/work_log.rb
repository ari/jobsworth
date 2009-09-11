# A work entry, belonging to a user & task
# Has a duration in seconds for work entries

class WorkLog < ActiveRecord::Base
  has_many(:custom_attribute_values, :as => :attributable, :dependent => :destroy, 
           # set validate = false because validate method is over-ridden and does that for us
           :validate => false)
  include CustomAttributeMethods

  belongs_to :user
  belongs_to :company
  belongs_to :project
  belongs_to :customer
  belongs_to :task
  belongs_to :scm_changeset

  has_one    :ical_entry, :dependent => :destroy
  has_one    :event_log, :as => :target, :dependent => :destroy
  has_many    :work_log_notifications, :dependent => :destroy
  has_many    :users, :through => :work_log_notifications

  named_scope :comments, :conditions => [ "work_logs.comment = 1 or work_logs.log_type = 6" ]

  validates_presence_of :started_at

  after_update { |r|
    r.ical_entry.destroy if r.ical_entry
    l = r.event_log
    l.created_at = r.started_at
    l.save

    if r.task && r.duration.to_i > 0
      r.task.recalculate_worked_minutes
      r.task.save
    end
  
  }

  after_create { |r|
    l = r.create_event_log
    l.company_id = r.company_id
    l.project_id = r.project_id
    l.user_id = r.user_id
    l.event_type = r.log_type
    l.created_at = r.started_at
    l.save
    
    if r.task && r.duration.to_i > 0
      r.task.recalculate_worked_minutes
      r.task.save
    end
    
  }

  after_destroy { |r|
    if r.task
      r.task.recalculate_worked_minutes
      r.task.save
    end
  
  }

  def self.full_text_search(q, options = {})
    return nil if q.nil? or q==""
    default_options = {:limit => 10, :page => 1}
    options = default_options.merge options
    options[:offset] = options[:limit] * (options.delete(:page).to_i-1)
    results = WorkLog.find_with_ferret(q, options)
    return [results.total_hits, results]
  end

  ###
  # Creates and saves a worklog for the given task.
  # If comment is given, it will be escaped before saving.
  # The newly created worklog is returned. 
  ###
  def self.create_for_task(task, user, comment)
    worklog = WorkLog.new
    worklog.user = user
    worklog.company = task.project.company
    worklog.customer = task.project.customer
    worklog.project = task.project
    worklog.task = task
    worklog.started_at = user.tz.utc_to_local(Time.now.utc)
    worklog.duration = 0
    worklog.log_type = EventLog::TASK_CREATED

    if !comment.blank?
      worklog.body =  CGI::escapeHTML(comment)
      worklog.comment = true
    end 
    
    worklog.save

    return worklog
  end

  def ended_at
    self.started_at + self.duration + self.paused_duration
  end

  # Sets the associated customer using the given name
  def customer_name=(name)
    self.customer = company.customers.find_by_name(name)
  end
  # Returns the name of the associated customer
  def customer_name
    customer.name if customer
  end

  alias :validate_custom_attributes :validate

  def validate
    if log_type == EventLog::TASK_WORK_ADDED
      validate_custom_attributes
    end 
  end

end
