###
# A task filter is used to find tasks matching the filters set up
# in session.
###
class TaskFilter < ActiveRecord::Base
  belongs_to :user
  belongs_to :company
  has_many(:qualifiers, :dependent => :destroy, :class_name => "TaskFilterQualifier")
  accepts_nested_attributes_for :qualifiers

  validates_presence_of :user

  before_create :set_company_from_user

  # Returns an array of all tasks matching conditions
  def tasks
    to_include = [ :users, :tags, :sheets, :todos, :dependencies, 
                   :milestone, :notifications, :watchers, 
                   :customers ]
    to_include << { :work_logs => :user }
    to_include << { :company => :properties }
    to_include << { :project => :customer }
    to_include << { :task_property_values => { :property_value => :property } }
    to_include << { :dependants => [:users, :tags, :sheets, :todos, 
                                    { :project => :customer }, :milestone ] }

    return user.company.tasks.all(:conditions => conditions, 
                                  :order => "tasks.id desc",
                                  :include => to_include,
                                  :limit => 100)
  end

  # Returns the count of tasks matching conditions
  def count
    user.company.tasks.count(:conditions => conditions)
  end

  # Returns a map of tags to their count in the current list. Only tags
  # with count > 0 will be included.
  def tag_counts
    if @tag_counts.nil?
      @tag_counts = {}
      tasks.each do |task|
        task.tags.each do |tag|
          @tag_counts[tag] = (@tag_counts[tag] || 0) + 1
        end
      end
    end

    return @tag_counts
  end

  # Returns an array of the conditions to use for a sql lookup
  # of tasks for this filter
  def conditions
    property_qualifiers = qualifiers.select { |q| q.qualifiable_type == "PropertyValue" }
    standard_qualifiers = qualifiers - property_qualifiers
    
    res = conditions_for_standard_qualifiers(standard_qualifiers)
    res += conditions_for_property_qualifiers(property_qualifiers)

    res = res.select { |c| !c.blank? }
    res = res.join(" AND ")

    return res
  end

  private

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

  # Returns the column name to use for lookup for the given
  # class_type
  def column_name_for(class_type)
    if class_type == "User"
      return "task_owners.user_id"
    elsif class_type == "Customer"
      return "projects.customer_id"
    elsif class_type == "Milestone"
      return "tasks.milestone_id"
    elsif class_type == "Tag"
      return "task_tags.tag_id"
    else
      return "#{ class_type.downcase }_id"
    end
  end
  
end
