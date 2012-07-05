# encoding: UTF-8
# A task
#
# Belongs to a project, milestone, creator
# Has many tags, users (through task_owners), tags (through task_tags),
#   dependencies (tasks which should be done before this one) and
#   dependants (tasks which should be done after this one),
#   todos, and sheets
#
class Task < AbstractTask

  after_validation :fix_work_log_error

  after_save { |r|
    r.ical_entry.destroy if r.ical_entry
    project = r.project
    project.update_project_stats
    project.save

    if r.project.id != r.project_id
      #Task has changed projects, update counts of target project as well
      p = Project.find(r.project_id)
      p.update_project_stats
      p.save
    end

    r.milestone.update_counts if r.milestone
  }

  before_save :calculate_score

  has_many :property_values, :through => :task_property_values

  scope :from_this_year, where("created_at > ?", Time.zone.now.beginning_of_year - 1.month)

  def ready?
    self.dependencies.reject{ |t| t.done? }.empty? && active? && !wait_for_customer
  end

  def active?
    self.hide_until.nil? || self.hide_until < Time.now.utc
  end 

  def self.expire_hide_until
    Task.where("hide_until IS NOT NULL").all.each{ |task|
      if task.hide_until < Time.now.utc
        task.hide_until=nil
        task.save!
      end
    }
  end

  def worked_on?
    self.sheets.size > 0
  end

  def scheduled_overdue?
    self.scheduled_date ? (self.scheduled_date.to_time <= Time.now.utc) : false
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
    self.worked_minutes = WorkLog.where("task_id = ?", self.id).sum(:duration).to_i / 60
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
    [customers.uniq.map{|c| c.name}.join(','), project.name, task_num, name, tags.collect(&:name).join(','), owners_to_display, milestone.nil? ? nil : milestone.name, self.due_date, created_at, completed_at, worked_minutes, duration, status_type ] +
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
      recipients= self.users.active.where("users.id != ? and users.receive_notifications = ?", user_who_made_change.id || 0, true)
    else
      recipients= self.users.active.where(:receive_notifications=>true)
      recipients<< user_who_made_change unless  user_who_made_change.nil? or user_who_made_change.id.nil? or recipients.include?(user_who_made_change)
    end
    recipients
  end

  ###
  # This method will mark this task as unread for any
  # setup watchers or task owners.
  # The exclude param should be a user which unread
  # status will not be updated. For example, the person who wrote a
  # comment should probably be excluded.
  ###
  def mark_as_unread(exclude = "")
    exclude = ["user_id !=?", exclude.id ] if exclude.is_a?(User)
    self.task_users.where(exclude).update_all(:unread => true)
  end

  def self.public_comments_for(task)
    customer_ids = task.customers.collect { |customer| customer.id }.join(', ')
    WorkLog.comments.
            where('customer_id in (?)', customer_ids).
            order('started_at DESC')
  end

  ###
  # Sets this task as read for user.
  # If read is passed, and false, sets the task
  # as unread for user.
  ###
  def set_task_read(user, read = true)
    self.task_users.where(:user_id=> user.id).update_all(:unread => !read)
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
      logs = work_logs.select("user_id, sum(duration) as duration").group("user_id")
      logs.each{|l| @user_work[l._user_] = l.duration if l._user_ && l.duration.to_i > 0}
    end

    return @user_work
  end

  def should_calculate_score?
    # Only calculate score if the task is open and it's not snozzed
    !(closed? or wait_for_customer?)
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
          mid = Milestone.order("completed_at").where('company_id = ? AND project_id = ? AND LTRIM(name) = ?', user.company.id, pid, val_arr[1].strip).first.id
          self.milestone_id = mid
        end
        self.project_id = pid
        save
      end
    elsif group == "resolution" && user.can?(self.project, 'close')
      status = Task::MAX_STATUS
      self.statuses_for_select_list.each do |arr|
        status = arr[1] if arr[0] == value
      end
      self.status = status
      save
    elsif prop = Property.find_by_company_id_and_name(user.company_id, group.camelize)
      if !value.blank?
        pv = PropertyValue.find_by_value_and_property_id(value, prop.id)
      elsif !icon.blank?
        icon = icon.split("?")[0]
        pv = PropertyValue.find_by_icon_url_and_property_id(icon, prop.id)
      end
      #prevent duplicate entry when user dragging task to same group
      if TaskPropertyValue.find_by_task_id_and_property_id(self.id, prop.id).try(:property_value_id) != pv.id
        self.set_property_value(prop, pv)
      end
    end
  end

  def update_score_with(score_rule)
    self.weight = (should_calculate_score?) ? 
                  score_rule.calculate_score_for(self) + self.weight_adjustment :
                  nil
    self.save
  end

  def score_rules
    score_rules = []
    score_rules.concat(project.score_rules) if self.project
    score_rules.concat(company.score_rules) if self.company
    score_rules.concat(milestone.score_rules) if self.milestone

    customers.each do |customer|
      score_rules.concat(customer.score_rules)
    end

    property_values.each do |property_value|
      score_rules.concat(property_value.score_rules)
    end

    score_rules
  end

  private

  def calculate_score
    # If the task is closed or snozzed, score should be nil
    unless should_calculate_score?
      weight = nil
      return true
    end

    all_score_rules = score_rules
    
    unless all_score_rules.empty?
      self.weight = all_score_rules.inject(self.weight_adjustment) do |result, score_rule|
        result + score_rule.calculate_score_for(self)
      end
    end
  end

  # If creating a new work log with a duration, fails because it work log
  # has a mandatory attribute missing, the error message it the unhelpful
  # "Work logs in invalid". Fix that here
  def fix_work_log_error
    if errors.include?("work_logs")
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
#  creator_id         :integer(4)
#  hide_until         :datetime
#  scheduled_at       :datetime
#  scheduled_duration :integer(4)
#  scheduled          :boolean(1)      default(FALSE)
#  worked_minutes     :integer(4)      default(0)
#  type               :string(255)     default("Task")
#  weight             :integer(4)      default(0)
#  weight_adjustment  :integer(4)      default(0)
#  wait_for_customer  :boolean(1)      default(FALSE)
#  estimate           :decimal(5, 2)
#
# Indexes
#
#  index_tasks_on_type_and_task_num_and_company_id  (type,task_num,company_id) UNIQUE
#  tasks_company_id_index                           (company_id)
#  tasks_due_at_idx                                 (due_at)
#  index_tasks_on_milestone_id                      (milestone_id)
#  tasks_project_completed_index                    (project_id,completed_at)
#  tasks_project_id_index                           (project_id,milestone_id)
#

