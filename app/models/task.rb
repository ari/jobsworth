# A task
#
# Belongs to a project, milestone, creator
# Has many tags, users (through task_owners), tags (through task_tags),
#   dependencies (tasks which should be done before this one) and
#   dependants (tasks which should be done after this one),
#   todos, and sheets
#
class Task < AbstractTask
  has_many      :work_logs, :dependent => :destroy, :order => "started_at asc"
  has_many      :sheets
  has_one       :ical_entry

  after_validation :fix_work_log_error

  after_create { |t| Trigger.fire(t, "create") }

  after_save { |r|
    r.ical_entry.destroy if r.ical_entry
    project = r.project(:readonly => false)
    project.update_project_stats
    project.save

    if r.project.id != r.project_id
      # Task has changed projects, update counts of target project as well
      p = Project.find(r.project_id)
      p.update_project_stats
      p.save
    end

    r.milestone.update_counts if r.milestone
  }

  def ready?
    self.dependencies.reject{ |t| t.done? }.empty?
  end

  def active?
    self.hide_until.nil? || self.hide_until < Time.now.utc
  end

  def worked_on?
    self.sheets.size > 0
  end

  def time_left
    res = 0
    if self.due_at != nil
      res = self.due_at - Time.now.utc
    end
    res
  end

  def scheduled_overdue?
    self.scheduled_date ? (self.scheduled_date.to_time <= Time.now.utc) : false
  end

  def started?
    worked_minutes > 0 || self.worked_on?
  end

  def scheduled_date
    if self.scheduled?
      if self.scheduled_at?
        self.scheduled_at
      elsif self.milestone
        self.milestone.scheduled_date
      end
    else
      if self.due_at?
        self.due_at
      elsif self.milestone
        self.milestone.scheduled_date
      end
    end
  end

  def scheduled_due_at
    if self.scheduled?
      self.scheduled_at
    else
      self.due_at
    end
  end

  def scheduled_duration
    if self.scheduled?
      @attributes['scheduled_duration'].to_i
    else
      self.duration.to_i
    end
  end

  def recalculate_worked_minutes
    self.worked_minutes = WorkLog.sum(:duration, :conditions => ["task_id = ?", self.id]).to_i / 60
  end

  def minutes_left
    minutes_left_by self.duration
  end

  def scheduled_minutes_left
    minutes_left_by self.scheduled_duration
  end

  def overworked?
    ((self.duration.to_i - self.worked_minutes) < 0 && (self.duration.to_i) > 0)
  end

  def self.search(user, keys)
    tf = TaskFilter.new(:user => user)

    conditions = []
    keys.each do |k|
      conditions << "tasks.task_num = #{ k.to_i }"
    end
    name_conds = Search.search_conditions_for(keys, [ "tasks.name" ], :search_by_id => false)
    conditions << name_conds[1...-1] # strip off surounding parentheses

    conditions = "(#{ conditions.join(" or ") })"
    return tf.tasks(conditions)
  end

  def worked_and_duration_class
    if worked_minutes > duration
      "overtime"
    else
      ""
    end
  end
  def csv_header
    ['Client', 'Project', 'Num', 'Name', 'Tags', 'User', 'Milestone', 'Due', 'Created', 'Completed', 'Worked', 'Estimated', 'Resolution'] +
      company.properties.collect { |property| property.name }
  end

  def to_csv
    [project.customer.name, project.name, task_num, name, tags.collect(&:name).join(','), owners_to_display, milestone.nil? ? nil : milestone.name, self.due_date, created_at, completed_at, worked_minutes, duration, status_type ] +
      company.properties.collect { |property| property_value(property).to_s }
  end

  ###
  # This method return value of property named "Type"
  ###
  def type
    property_value(company.type_property)
  end

  ###
  # Returns an int to use for sorting this task. See Company.rank_by_properties
  # for more info.
  ###
  def sort_rank
    @sort_rank ||= company.rank_by_properties(self)
  end

  ###
  # A task is critical if it is in the top 20% of the possible
  # ranking using the companys sort.
  ###
  def critical?
    return false if company.maximum_sort_rank == 0

    sort_rank.to_f / company.maximum_sort_rank.to_f > 0.80
  end

  ###
  # A task is normal if it is not critical or low.
  ###
  def normal?
    !critical? and !low?
  end

  ###
  # A task is low if it is in the bottom 20% of the possible
  # ranking using the companys sort.
  ###
  def low?
    return false if company.maximum_sort_rank == 0

    sort_rank.to_f / company.maximum_sort_rank.to_f < 0.20
  end

  def users_to_notify(user_who_made_change=nil)
    if user_who_made_change and !user_who_made_change.receive_own_notifications?
      recipients= self.users.find(:all, :conditions=>  ["users.id != ? and users.receive_notifications = ?", user_who_made_change.id, true])
    else
      recipients= self.users.find(:all, :conditions=>  { :receive_notifications=>true})
      recipients<< user_who_made_change unless  user_who_made_change.nil? or recipients.include?(user_who_made_change)
    end
    recipients
  end

  ###
  # Returns an array of email addresses of people who should be
  # notified about changes to this task.
  ###
  def notification_email_addresses(user_who_made_change = nil)

    emails = users_to_notify(user_who_made_change).map { |u| u.email }

    # add in notify emails
    if !notify_emails.blank?
      emails += notify_emails_array
    end
    emails = emails.compact.map { |e| e.strip }

    # and finally remove dupes
    emails = emails.uniq

    return emails
  end

  ###
  # This method will mark this task as unread for any
  # setup watchers or task owners.
  # The exclude param should be a user or array of users whose unread
  # status will not be updated. For example, the person who wrote a
  # comment should probably be excluded.
  ###
  def mark_as_unread(exclude = [])
    exclude = [ exclude ].flatten # make sure it's an array.

    self.task_users.each do |n|
      n.update_attribute(:unread, true) if !exclude.include?(n.user)
    end
  end

  ###
  # Sets this task as read for user.
  # If read is passed, and false, sets the task
  # as unread for user.
  ###
  def set_task_read(user, read = true)
    user_notifications = self.task_users.select { |n| n.user == user }
    user_notifications.each do |n|
      n.update_attributes(:unread => !read)
    end
  end

  ###
  # Returns true if this task is marked as unread for user.
  ###
  def unread?(user)
    unread = false

    user_notifications = self.task_users.select { |n| n.user == user }
    user_notifications.each do |n|
      unread ||= n.unread?
    end

    return unread
  end


  # return a users mapped to the duration of time they have worked on this task
  def user_work
    if @user_work.nil?
      @user_work = {}
      logs = work_logs.all(:select => "user_id, sum(duration) as duration", :group => "user_id")
      logs.each do |l|
        user = User.find(l.user_id)
        @user_work[user] = l.duration if l.duration.to_i > 0
      end
    end

    return @user_work
  end

  def repeat_task
    repeat = self.clone
    repeat.due_at = repeat.next_repeat_date
    repeat.tags << self.tags
    repeat.watchers= self.watchers
    repeat.owners = self.owners
    repeat.dependencies = self.dependencies
    repeat.save!
  end

  def update_group(user, group, value, icon = nil)
    if group == "milestone"
      val_arr = value.split("/")
      task_project = user.projects.find_by_name(val_arr[0])
      if user.can?(task_project, "milestone")
        pid = task_project.id
        if val_arr.size == 1
          self.milestone_id = nil
        else
          mid = Milestone.find(:first, :conditions => ['company_id = ? AND project_id = ? AND completed_at IS NULL AND LTRIM(name) = ?', user.company.id, pid, val_arr[1].strip]).id
          self.milestone_id = mid
        end
        self.project_id = pid
        save
      end
    elsif group == "resolution" && user.can?(self.project, 'close')
      p = Status.find_by_name_and_company_id(value, user.company_id).id
      self.status = (p - 1)
      save
    elsif prop = Property.find_by_company_id_and_name(user.company_id, group.camelize)
      if !value.blank?
        pv = PropertyValue.find_by_value_and_property_id(value, prop.id)
      elsif !icon.blank?
        icon = icon.split("?")[0]
        pv = PropertyValue.find_by_icon_url_and_property_id(icon, prop.id)
      end
      self.set_property_value(prop, pv)
    end
  end

  private

  # If creating a new work log with a duration, fails because it work log
  # has a mandatory attribute missing, the error message it the unhelpful
  # "Work logs in invalid". Fix that here
  def fix_work_log_error
    if errors.key?("work_logs")
      errors.delete("work_logs")
      self.work_logs.last.errors.each_full do |msg|
        self.errors.add(:base, msg)
      end
    end
  end

  def minutes_left_by(duration)
    d = duration.to_i - self.worked_minutes
    d = 240 if d < 0 && duration.to_i > 0
    d = 0 if d < 0
    d
  end
end


# == Schema Information
#
# Table name: tasks
#
#  id                 :integer(4)      not null, primary key
#  name               :string(200)     default(""), not null
#  project_id         :integer(4)      default(0), not null
#  position           :integer(4)      default(0), not null
#  created_at         :datetime        not null
#  due_at             :datetime
#  updated_at         :datetime        not null
#  completed_at       :datetime
#  duration           :integer(4)      default(1)
#  hidden             :integer(4)      default(0)
#  milestone_id       :integer(4)
#  description        :text
#  company_id         :integer(4)
#  priority           :integer(4)      default(0)
#  updated_by_id      :integer(4)
#  severity_id        :integer(4)      default(0)
#  type_id            :integer(4)      default(0)
#  task_num           :integer(4)      default(0)
#  status             :integer(4)      default(0)
#  requested_by       :string(255)
#  creator_id         :integer(4)
#  notify_emails      :string(255)
#  repeat             :string(255)
#  hide_until         :datetime
#  scheduled_at       :datetime
#  scheduled_duration :integer(4)
#  scheduled          :boolean(1)      default(FALSE)
#  worked_minutes     :integer(4)      default(0)
#  type               :string(255)     default("Task")
#
# Indexes
#
#  index_tasks_on_type_and_task_num_and_company_id  (type,task_num,company_id) UNIQUE
#  tasks_project_id_index                           (project_id,milestone_id)
#  tasks_company_id_index                           (company_id)
#  tasks_project_completed_index                    (project_id,completed_at)
#  index_tasks_on_milestone_id                      (milestone_id)
#  tasks_due_at_idx                                 (due_at)
#

