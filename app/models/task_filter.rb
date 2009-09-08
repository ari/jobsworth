###
# A task filter is used to find tasks matching the filters set up
# in session.
###
class TaskFilter < ActiveRecord::Base
  belongs_to :user
  belongs_to :company
  has_many(:qualifiers, :dependent => :destroy, :class_name => "TaskFilterQualifier")
  accepts_nested_attributes_for :qualifiers

  has_many :keywords, :dependent => :destroy

  validates_presence_of :user
  validates_presence_of :name

  named_scope :shared, :conditions => { :shared => true }
  named_scope :visible, :conditions => { :system => false }

  before_create :set_company_from_user

  # Returns the system filter for the given user. If none is found, 
  # create and saves a new one and returns that.
  def self.system_filter(user)
    filter = user.task_filters.first(:conditions => { :system => true })
    if filter.nil?
      filter = user.task_filters.build(:name => "System filter for #{ user }", 
                                       :user_id => user.id, :system => true)
      filter.save!
    end

    return filter
  end

  # Returns an array of all tasks matching the conditions from this filter.
  # If extra_conditions is passed, that will be ANDed to the conditions
  # If limit is false, no limit will be set on the tasks returned (otherwise
  # a default limit will be applied)
  def tasks(extra_conditions = nil, limit_tasks = true)
    limit = (limit_tasks ? 500 : nil)
    return user.company.tasks.all(:conditions => conditions(extra_conditions), 
                                  :order => "tasks.id desc",
                                  :include => to_include,
                                  :limit => limit)
  end

  # Returns the count of tasks matching the conditions of this filter.
  # if extra_conditions is passed, that will be ANDed to the conditions
  def count(extra_conditions = nil)
    user.company.tasks.count(:conditions => conditions(extra_conditions),
                             :include => to_include)
  end

  # Returns a count to display for this filter. The count represents the
  # number of tasks that look they need attention for the given user - 
  # unassigned tasks and unread tasks are counted.
  # The value will be cached and re-used unless force_recount is passed.
  def display_count(user, force_recount = false)
    @display_count = nil if force_recount

    count_conditions = []
    count_conditions << "(task_owners.unread = 1 and task_owners.user_id = #{ user.id })" 
    count_conditions << "(notifications.unread = 1 and notifications.user_id = #{ user.id })" 
    count_conditions << "(task_owners.id is null)"

    sql = count_conditions.join(" or ")
    sql = "(#{ sql })"
    @display_count ||= count(sql)
  end
  
  # Returns an array of the conditions to use for a sql lookup
  # of tasks for this filter
  def conditions(extra_conditions = nil)
    status_qualifiers = qualifiers.select { |q| q.qualifiable_type == "Status" }
    property_qualifiers = qualifiers.select { |q| q.qualifiable_type == "PropertyValue" }
    customer_qualifiers = qualifiers.select { |q| q.qualifiable_type == "Customer" }
    standard_qualifiers = qualifiers - property_qualifiers - status_qualifiers - customer_qualifiers
    
    res = conditions_for_standard_qualifiers(standard_qualifiers)
    res += conditions_for_property_qualifiers(property_qualifiers)
    res << conditions_for_status_qualifiers(status_qualifiers)
    res << conditions_for_customer_qualifiers(customer_qualifiers)
    res << conditions_for_keywords
    res << extra_conditions if extra_conditions
    res << user.user_tasks_sql

    res = res.select { |c| !c.blank? }
    res = res.join(" AND ")

    return res
  end

  # Sets the keywords for this filter using the given array
  def keywords_attributes=(new_keywords)
    keywords.clear

    (new_keywords || []).each do |word|
      keywords.build(:word => word)
    end
  end

  private

  def to_include
    to_include = [ :users, :tags, :sheets, :todos, :dependencies, 
                   :milestone, :notifications, :watchers, 
                   :customers, :task_property_values ]
    to_include << { :company => :properties }
    to_include << { :project => :customer }
  end

  def set_company_from_user
    self.company = user.company
  end

  # Returns a conditions hash the will filter tasks based on the
  # given property value qualifiers
  def conditions_for_property_qualifiers(property_qualifiers)
    name = "task_property_values.property_value_id"
    grouped = property_qualifiers.group_by { |q| q.qualifiable.property }
    
    res = []
    grouped.each do |property, qualifiers|
      ids = qualifiers.map { |q| q.qualifiable.id }
      res << "#{ name } IN (#{ ids.join(", ") })"
    end

    return res
  end

  # Returns an array of conditions that will filter tasks based on the
  # given standard qualifiers.
  # Standard qualifiers are things like project, milestone, user, where
  # a filter will OR the different users, but and between different types
  def conditions_for_standard_qualifiers(standard_qualifiers)
    res = []

    grouped_conditions = standard_qualifiers.group_by { |q| q.qualifiable_type }
    grouped_conditions.each do |type, values|
      name = column_name_for(type)
      ids = values.map { |v| v.qualifiable_id }
      res << "#{ name } in (#{ ids.join(",") })"
    end

    return res
  end

  # Returns a string sql fragment that will limit tasks to 
  # those that match the set keywords
  def conditions_for_keywords
    res = []

    keywords.each do |kw|
      str = "lower(tasks.name) like '%#{ kw.word.downcase }%'"
      str += " or lower(tasks.description) like '%#{ kw.word.downcase }%'"
      res << str
    end

    res = res.join(" or ")
    return "(#{ res })" if !res.blank?
  end

  # Returns a sql string fragment that will limit tasks to only
  # status set by the status qualifiers.
  # Status qualifiers have to be handled especially until the
  # migration from an array in code to db backed statuses is complete
  def conditions_for_status_qualifiers(status_qualifiers)
    old_status_ids = []
    c = company || user.company
    
    status_qualifiers.each do |q|
      status = q.qualifiable
      old_status = c.statuses.index(status)
      old_status_ids << old_status
    end
    
    old_status_ids = old_status_ids.join(",")
    return "tasks.status in (#{ old_status_ids })" if !old_status_ids.blank?
  end

  # Returns a sql string fragment that will limit tasks to only
  # those in a project belonging to customers, or linked directly 
  # to the customer
  def conditions_for_customer_qualifiers(customer_qualifiers)
    ids = customer_qualifiers.map { |q| q.qualifiable.id }
    ids = ids.join(",")

    if !ids.blank?
      res = "projects.customer_id in (#{ ids })"
      res += " or task_customers.customer_id in (#{ ids })"
      return "(#{ res })"
    end
  end

  # Returns the column name to use for lookup for the given
  # class_type
  def column_name_for(class_type)
    if class_type == "User"
      return "task_owners.user_id"
    elsif class_type == "Project"
      return "tasks.project_id"
    elsif class_type == "Task"
      return "tasks.id"
    elsif class_type == "Customer"
      return "projects.customer_id"
    elsif class_type == "Company"
      return "tasks.company_id"
    elsif class_type == "Milestone"
      return "tasks.milestone_id"
    elsif class_type == "Tag"
      return "task_tags.tag_id"
    else
      return "#{ class_type.downcase }_id"
    end
  end
  
end
