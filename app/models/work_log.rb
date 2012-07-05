# encoding: UTF-8

# A work entry, belonging to a user & task
# Has a duration in seconds for work entries

class WorkLog < ActiveRecord::Base
  APPROVED=1
  REJECTED=2
  ['APPROVED', 'REJECTED'].each do |status_name|
    define_method(status_name.downcase + '?') { status == self.class.const_get(status_name) }
  end

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
  has_many   :email_deliveries
  has_many   :project_files

  scope :worktimes, where("work_logs.duration > 0")
  scope :comments, where("work_logs.body IS NOT NULL AND work_logs.body <> ''")
  #check all access rights for user
  scope :on_tasks_owned_by, lambda { |user|
    select("work_logs.*").joins("INNER JOIN tasks ON work_logs.task_id = tasks.id INNER JOIN task_users ON work_logs.task_id = task_users.task_id").where("task_users.user_id = ?", user)
  }
  scope :accessed_by, lambda { |user|
    readonly(false).joins(
      "join projects on work_logs.project_id = projects.id join project_permissions on project_permissions.project_id = projects.id join users on project_permissions.user_id= users.id"
    ).includes(:task).where(
      "projects.completed_at is NULL and users.id=? and (project_permissions.can_see_unwatched = ? or users.id in(select task_users.user_id from task_users where task_users.task_id=tasks.id)) and work_logs.company_id = ? AND work_logs.access_level_id <= ? ", user.id, true, user.company_id, user.access_level_id
    )
  }

  scope :level_accessed_by, lambda { |user|
    where("work_logs.access_level_id <= ?", user.access_level_id)
  }

  scope :all_accessed_by, lambda { |user|
    readonly(false).includes(:task).joins(
      "join project_permissions on work_logs.project_id = project_permissions.project_id join users on project_permissions.user_id= users.id"
    ).where(
      "users.id = ? and (project_permissions.can_see_unwatched=? or users.id in (select task_users.user_id from task_users where task_users.task_id=tasks.id)) and work_logs.access_level_id <= ?", user.id, true, user.access_level_id
    )
  }

  validates_presence_of :started_at
  validate :validate_logs
  attr_protected :status

  after_update { |r|
    r.ical_entry.destroy if r.ical_entry

    if r.task && r.duration.to_i > 0
      r.task.recalculate_worked_minutes
      r.task.save
    end

  }

  after_create { |r|
    if r.task && r.duration.to_i > 0
      r.task.recalculate_worked_minutes
      r.task.save
    end

    # mark task as unread
    if r.comment?
      r.task.task_users.joins(:user).where("task_users.user_id <> ?", r.user_id).where("users.access_level_id >= ?", r.access_level_id).update_all(:unread => true)
    end

    # reopens task if it's done
    if r.comment? && r.task.done? && (!r.event_log || r.event_log.event_type == EventLog::TASK_COMMENT)
      r.task.update_attributes(
        :completed_at => nil,
        :status => Task.status_types.index("Open")
      )
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
  # If anything goes wrong, raise an exception
  ###
  def self.create_task_created!(task, user)
    worklog = WorkLog.new(:user => user, :body => task.description)
    worklog.for_task(task)
    worklog.save!

    worklog.create_event_log(
      :user       => user,
      :event_type => EventLog::TASK_CREATED,
      :company    => worklog.company,
      :project    => worklog.project
    )

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
      end
      if (user.option_tracktime.to_i == 1) and !work_log_params[:duration].blank?
        work_log_params[:duration] = TimeParser.parse_time(user, work_log_params[:duration])
        if work_log_params[:started_at].blank?
          work_log_params[:started_at] = Time.now.utc
        else
          work_log_params[:started_at] = TimeParser.date_from_string(user, work_log_params[:started_at])
        end
      else
        work_log_params[:duration] = 0
        work_log_params[:started_at]=Time.now.utc
      end
      work_log_params[:user] = user
      work_log_params[:company]= task.company
      work_log_params[:project] = task.project
      work_log_params[:customer] = (task.customers.first || task.project.customer)

      work_log = task.work_logs.build(work_log_params)
      event_log = work_log.create_event_log(
        :user        =>  user,
        :event_type  =>  work_log.worktime? ? EventLog::TASK_WORK_ADDED : EventLog::TASK_COMMENT,
        :project     =>  task.project,
        :company     =>  task.company
      )
      return work_log
    else
      return false
    end
  end

  def comment?
    ! self.body.blank?
  end

  def worktime?
    self.duration > 0
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
    validate_custom_attributes if self.worktime?
  end

  def notify(files=[])
    self.project_files = files unless files.empty?
    emails = (access_level_id > 1) ? [] : task.email_addresses
    users = task.users_to_notify(user).select{ |user| user.access_level_id >= self.access_level_id }

    # only send to user once
    user_emails = users.collect {|u| u.email_addresses.collect{|ea| ea.email} }.flatten
    emails.reject! {|ea| user_emails.include?(ea.email) }

    emails += users.map { |u| u.email_addresses.detect{ |pv| pv.default } }
    emails = emails.uniq.compact

    emails.each do |email|
      EmailDelivery.new(:status=>"queued", :email=>email.email, :user=>email.user, :work_log=>self).save!
    end

    email_deliveries.where(:status => "queued").each{|ed| ed.deliver} unless Rails.env == 'production'
  end

  def for_task(task)
    if (_user_.nil? and self.email_address.nil?)
      self.email_address_id = task.updated_by_id
      self.user= User.where('email_addresses.id' => email_address_id).joins(:email_addresses).first
    end
    self.task=task
    self.project=task.project
    self.company= task.project.company
    self.customer= task.project.customer
    self.started_at= Time.now.utc
    self.duration = 0
    self
  end

  # create user accessor to rewrite user association
  def user
    if _user_.nil?
      User.new(:name => "Unknown User (#{email_address.email})", :email => email_address.email, :company => company) #
    else
      _user_
    end
  end

  def user=(u)
    self._user_ = u
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
#  paused_duration  :integer(4)      default(0)
#  exported         :datetime
#  status           :integer(4)      default(0)
#  access_level_id  :integer(4)      default(1)
#  email_address_id :integer(4)
#
# Indexes
#
#  work_logs_company_id_index                 (company_id)
#  work_logs_customer_id_index                (customer_id)
#  work_logs_project_id_index                 (project_id)
#  work_logs_task_id_index                    (task_id,log_type)
#  index_work_logs_on_task_id_and_started_at  (task_id,started_at)
#  work_logs_user_id_index                    (user_id,task_id)
#

