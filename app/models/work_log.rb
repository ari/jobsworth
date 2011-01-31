# encoding: UTF-8

# A work entry, belonging to a user & task
# Has a duration in seconds for work entries

class WorkLog < ActiveRecord::Base
  has_many(:custom_attribute_values, :as => :attributable, :dependent => :destroy,
           # set validate = false because validate method is over-ridden and does that for us
           :validate => false)
  include CustomAttributeMethods

  belongs_to :_user_, :class_name => "User", :foreign_key => "user_id"
  belongs_to :email_address
  belongs_to :company
  belongs_to :project
  belongs_to :customer
  belongs_to :task, :class_name=>"AbstractTask", :foreign_key=>'task_id'
  belongs_to :access_level

  has_one    :ical_entry, :dependent => :destroy
  has_one    :event_log, :as => :target, :dependent => :destroy
  has_many    :work_log_notifications, :dependent => :destroy
  has_many    :users, :through => :work_log_notifications
  has_many   :email_deliveries
  has_many   :project_files

  scope :comments, where("work_logs.comment = ? or work_logs.log_type = ?", true, EventLog::TASK_COMMENT)
  #check all access rights for user
  scope :on_tasks_owned_by, lambda { |user|
    select("work_logs.*").joins("INNER JOIN tasks ON work_logs.task_id = tasks.id INNER JOIN task_users ON work_logs.task_id = task_users.task_id").where("task_users.user_id = ?", user)
  }
  scope :accessed_by, lambda { |user|
    readonly(false).joins(
      "join projects on work_logs.project_id = projects.id join project_permissions on project_permissions.project_id = projects.id join users on project_permissions.user_id= users.id"
    ).includes(:task).where(
      "projects.completed_at is NULL and users.id=? and (project_permissions.can_see_unwatched = true or users.id in(select task_users.user_id from task_users where task_users.task_id=tasks.id)) and work_logs.company_id = ? AND work_logs.access_level_id <= ? ", user.id, user.company_id, user.access_level_id
    )
  }

  scope :level_accessed_by, lambda { |user|
    where("work_logs.access_level_id <= ?", user.access_level_id)
  }

  scope :all_accessed_by, lambda { |user|
    readonly(false).includes(:task).joins(
      "join project_permissions on work_logs.project_id = project_permissions.project_id join users on project_permissions.user_id= users.id"
    ).where(
      "users.id = ? and (project_permissions.can_see_unwatched = true or users.id in (select task_users.user_id from task_users where task_users.task_id=tasks.id)) and work_logs.access_level_id <= ?", user.id, user.access_level_id
    )
  }

  validates_presence_of :started_at
  validate :validate_logs

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

  ###
  # Creates and saves a worklog for the given task.
  # The newly created worklog is returned.
  # If anything goes worng, raise an exception
  ###
  def self.create_task_created!(task, user)
    worklog = WorkLog.new
    worklog.user = user
    worklog.for_task(task)
    worklog.log_type = EventLog::TASK_CREATED
    worklog.body=   task.description

    #worklog.comment = ??????
    worklog.save!

    return worklog
  end

  # Builds a new (unsaved) work log for task using the given params
  # params must look like {:work_log=>{...},:comment=>""}
  # build only if we have :duration or :comment else retur false
  def self.build_work_added_or_comment(task, user, params=nil)
    work_log_params=params[:work_log].nil? ? {} : params[:work_log].clone
    if (work_log_params and !work_log_params[:duration].blank?) or (params and !params[:comment].blank?)
      unless params[:comment].blank?
        work_log_params[:body] = params[:comment]
        work_log_params[:log_type]=EventLog::TASK_COMMENT
        work_log_params[:comment] =true
      end
      if (user.option_tracktime.to_i == 1) and !work_log_params[:duration].blank?
        work_log_params[:duration] = TimeParser.parse_time(user, work_log_params[:duration])
        if (work_log_params[:started_at].blank?)
          work_log_params[:started_at] = Time.now.utc
        else
          work_log_params[:started_at] = TimeParser.date_from_params(user, work_log_params, :started_at)
        end
        work_log_params[:log_type] = EventLog::TASK_WORK_ADDED
      else
        work_log_params[:duration]=0
        work_log_params[:started_at]=Time.now.utc
      end
      work_log_params[:user]=user
      work_log_params[:company]= task.company
      work_log_params[:project] = task.project
      work_log_params[:customer] = (task.customers.first || task.project.customer)
      task.work_logs.build( work_log_params)
    else
      return false
    end
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

  def validate_logs
    if log_type == EventLog::TASK_WORK_ADDED
      validate_custom_attributes
    end
  end

  def notify(files=[])
    mark_as_unread
    self.project_files = files unless files.empty?
    emails = (access_level_id > 1) ? [] : task.email_addresses
    users = task.users_to_notify(user).select{ |user| user.access_level_id >= self.access_level_id }
    emails += users.map { |u| u.email_addresses.detect{ |pv| pv.default } }
    emails = emails.uniq.compact
    self.users = users

    emails.each do |email|
      EmailDelivery.new(:status=>"queued", :email_address=>email, :work_log=>self).save!
    end

    email_deliveries.where(:status => "queued").each{|ed| ed.deliver} unless Rails.env == 'production'
  end

  def for_task(task)
    self.task=task
    self.project=task.project
    self.company= task.project.company
    self.customer= task.project.customer
    self.started_at= Time.now.utc
    self.duration = 0
  end

  #create user accessor to rewrite user association
  def user
    if _user_.nil?
      User.new(:name=>"Unknown User (#{email_address.email})", :email=> email_address.email, :company => company)
    else
      _user_
    end
  end

  def user=(u)
    self._user_ = u
  end

protected
  def mark_as_unread
    ids = task.users.where(["users.access_level_id <?", access_level_id]).select("users.id").map{ |u| u.id } << user_id
    task.mark_as_unread(["user_id not in (?)", ids])
  end
end




# == Schema Information
#
# Table name: work_logs
#
#  id               :integer(4)      not null, primary key
#  user_id          :integer(4)      default(0)
#  task_id          :integer(4)
#  project_id       :integer(4)      default(0), not null
#  company_id       :integer(4)      default(0), not null
#  customer_id      :integer(4)      default(0), not null
#  started_at       :datetime        not null
#  duration         :integer(4)      default(0), not null
#  body             :text
#  log_type         :integer(4)      default(0)
#  paused_duration  :integer(4)      default(0)
#  comment          :boolean(1)      default(FALSE)
#  exported         :datetime
#  approved         :boolean(1)
#  access_level_id  :integer(4)      default(1)
#  email_address_id :integer(4)
#

