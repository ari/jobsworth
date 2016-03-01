# encoding: UTF-8

# A work entry, belonging to a user & task
# Has a duration in seconds for work entries

class WorkLog < ActiveRecord::Base
  APPROVED = 1
  REJECTED = 2
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

  validates_presence_of :started_at
  validate :validate_logs

  delegate :recalculate_worked_minutes!, :to => :task, :allow_nil => true

  after_create  :manage_associated_task
  after_update  :update_associated_task_and_ical
  after_destroy :recalculate_worked_minutes!

  scope :worktimes, -> { where("work_logs.duration > 0") }
  scope :comments, -> { where("work_logs.body IS NOT NULL AND work_logs.body <> ''") }
  scope :duration_per_user, -> {
    select('work_logs.user_id, SUM(work_logs.duration) as duration, MIN(work_logs.started_at) as started_at')
    .group('work_logs.user_id')
  }

  #check all access rights for user
  scope :on_tasks_owned_by, lambda { |user|
    select('work_logs.*')
    .joins('INNER JOIN tasks ON work_logs.task_id = tasks.id
            INNER JOIN task_users ON work_logs.task_id = task_users.task_id')
    .where('task_users.user_id' => user)
  }

  scope :accessed_by, lambda { |user|
    readonly(false).joins(%q{
      JOIN projects ON work_logs.project_id = projects.id
      JOIN project_permissions ON project_permissions.project_id = projects.id
      JOIN users ON project_permissions.user_id= users.id}
    ).joins(:task).where(%q{
      projects.completed_at IS NULL AND
      users.id = ? AND
      ( project_permissions.can_see_unwatched = ? OR
        users.id IN ( SELECT task_users.user_id
                      FROM task_users
                      WHERE task_users.task_id=tasks.id )) AND
      work_logs.company_id = ? AND
      work_logs.access_level_id <= ? }, user.id, true, user.company_id, user.access_level_id
    )
  }

  scope :level_accessed_by, lambda { |user|
    where("work_logs.access_level_id <= ?", user.access_level_id)
  }

  scope :all_accessed_by, lambda { |user|
    readonly(false).joins(:task).joins(%q{
      JOIN project_permissions ON work_logs.project_id = project_permissions.project_id
      JOIN users               ON project_permissions.user_id = users.id}
    ).where(%q{
      users.id = ? AND
      ( project_permissions.can_see_unwatched = ? OR
        users.id IN (
          SELECT task_users.user_id
          FROM task_users
          WHERE task_users.task_id = tasks.id)) AND
      work_logs.access_level_id <= ?}, user.id, true, user.access_level_id
    )
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
        work_log_params[:duration] = TimeParser.parse_time(work_log_params[:duration])
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
      work_log_params[:company] = task.company
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
    self.body.present?
  end

  def comment_event_log?
    !event_log || event_log.event_type == EventLog::TASK_COMMENT
  end

  def worktime?
    self.duration > 0
  end

  def ended_at
    self.started_at + self.duration * 60
  end

  # Sets the associated customer using the given name
  def customer_name=(name)
    self.customer = company.customers.find_by(:name => name)
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
    emails = (access_level_id > 1) ? [] : task.email_addresses.to_a
    users = task.users_to_notify(user).select{ |user| user.access_level_id >= self.access_level_id }

    # only send to user once
    user_emails = users.collect {|u| u.email_addresses.collect{|ea| ea.email} }.flatten
    emails.reject! {|ea| user_emails.include?(ea.email) }

    emails += users.map { |u| u.email_addresses.detect{ |pv| pv.default } }
    emails = emails.uniq.compact

    emails.each do |email|
      EmailDelivery.create!(status: 'queued', email: email.email, user: email.user, work_log: self)
    end
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
      User.new(:name => "Unknown User (#{email_address.try(:email)})", :email => email_address.try(:email), :company => company) #
    else
      _user_
    end
  end

  def user=(u)
    self._user_ = u
  end

private
  def mark_unread_for_users
    q = task.task_users
      .joins(:user)
      .where('users.access_level_id >= ?', self.access_level_id)
    # Do not <> on NULL, see https://dev.mysql.com/doc/refman/5.0/en/working-with-null.html
    if self.user_id.present?
      q = q.where('task_users.user_id <> ?', self.user_id)
    end
    q.update_all(:unread => true)
  end

  def manage_associated_task
    recalculate_worked_minutes! if duration.to_i > 0
    mark_unread_for_users       if comment?
    task.reopen!                if comment? && task.done? && comment_event_log?
  end

  def update_associated_task_and_ical
    ical_entry.destroy          if ical_entry
    recalculate_worked_minutes! if duration.to_i > 0
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

