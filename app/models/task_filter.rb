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
  named_scope :visible, :conditions => { :system => false, :recent_for_user_id=>nil}
  named_scope :recent_for, lambda {|user| { :conditions=>{ :recent_for_user_id => user.id}, :order=>"id desc" } }
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
    return Task.all_accessed_by(user).all(:conditions => conditions(extra_conditions),
                                  :include => to_include,
                                  :limit => limit)
  end

  # Returns an array of all tasks matching the conditions from this filter.
  def tasks_for_jqgrid(parameters)
    tasks_all(parse_jqgrid_params(parameters))
  end

  # Returns an array of all tasks matching the conditions from this filter.
  def tasks_for_fullcalendar(parameters)
    tasks(parse_fullcalendar_params(parameters))
  end

  # Returns an array of all tasks matching the conditions from this filter.
  # If :conditions is passed, that will be ANDed to the conditions
  # if :include is passed, that will be ANDed to the to_include
  # also support :order, :limit
  def tasks_all(parameters={ })
    parameters[:conditions]=conditions(parameters[:conditions])
    parameters[:include]= to_include + (parameters[:include]||[])
    return Task.all_accessed_by(user).all(parameters)
  end

  # Returns the count of tasks matching the conditions of this filter.
  # if extra_conditions is passed, that will be ANDed to the conditions
  def count(extra_conditions = nil)
    Task.all_accessed_by(user).count(:conditions => conditions(extra_conditions),
                             :include => to_include)
  end

  # Returns a count to display for this filter. The count represents the
  # number of tasks that look they need attention for the given user -
  # unassigned tasks and unread tasks are counted.
  # The value will be cached and re-used unless force_recount is passed.
  def display_count(user, force_recount = false)
    @display_count = nil if force_recount
    @display_count ||= count(unread_conditions(user, true))
  end

  # Returns an array of the conditions to use for a sql lookup
  # of tasks for this filter
  def conditions(extra_conditions = nil)
    time_qualifiers = qualifiers.select { |q| q.qualifiable_type == "TimeRange" }
    status_qualifiers = qualifiers.select { |q| q.qualifiable_type == "Status" }
    property_qualifiers = qualifiers.select { |q| q.qualifiable_type == "PropertyValue" }
    customer_qualifiers = qualifiers.select { |q| q.qualifiable_type == "Customer" }
    standard_qualifiers = (qualifiers - property_qualifiers - status_qualifiers -
                           customer_qualifiers - time_qualifiers)

    res = conditions_for_standard_qualifiers(standard_qualifiers)
    res += conditions_for_property_qualifiers(property_qualifiers)
    res << conditions_for_status_qualifiers(status_qualifiers)
    res << conditions_for_customer_qualifiers(customer_qualifiers)
    res << conditions_for_time_qualifiers(time_qualifiers)
    res << conditions_for_keywords
    res << extra_conditions if extra_conditions
    res << unread_conditions(user) if unread_only?

    res = res.select { |c| !c.blank? }
    res = res.join(" AND ")

    return res
  end

  # Sets the keywords for this filter using the given array
  def keywords_attributes=(new_keywords)
    keywords.clear

    (new_keywords || []).each do |kw|
      keywords.build(kw)
    end
  end

  def cache_key
    key = super

    if unread_only?
      # we can't cache the whole filter when unread_only set
      "#{ key }/Time.now.to_i/#{ user.id }/#{ rand }/"
    else
      last_task_update = user.company.tasks.maximum(:updated_at,
                                                    :conditions => conditions,
                                                    :include => to_include)
      "#{ key }/#{ last_task_update.to_i }/#{ user.id }"
    end
  end
  def copy_from(filter)
    self.unread_only = filter.unread_only
    filter.qualifiers.each { |q| self.qualifiers << q.clone }
    filter.keywords.each do |kw|
      # N.B Shouldn't have to pass in all these values, but it
      # doesn't work when we don't, so...
      self.keywords.build(:task_filter => self,
                             :company => filter.company,
                             :word => kw.word)
    end
  end

  def store_for(user)
    if (TaskFilter.recent_for(user).count >= 10)
      TaskFilter.recent_for(user).last.destroy
    end
    filter=TaskFilter.new(:recent_for_user_id=>user.id, :user=>user, :company=>self.company)
    filter.name= generate_name
    filter.name= self.name if filter.name.blank?
    filter.copy_from(self)
    filter.save!
  end
private
 ###
  # This method generate filter name based on qualifiers and keywords
  # this name will include first project, milestone, status, client, user qualifier in this order
  # then all keywords, then other qualifiers
  # also name include only 3 items.
  # Method is too complex, would be happy if we can remove order and just cat first 3 items
  ###
  def generate_name
    counter = 0
    arr=[]
    types=["Project", "Milestone", "Status", "Client", "User"]
    types.each do |type|
      qualifier = qualifiers.detect{ |q| q.qualifiable_type == type }
      unless qualifier.nil?
        counter +=1
        arr<< (qualifier.reversed? ? 'not ' : '') + qualifier.qualifiable.to_s
      end
      if counter == 3
        return arr.join(', ')
      end
    end
    keywords.each do |kw|
      counter += 1
      arr<< (kw.reversed? ? 'not ' : '') + kw.word;
      if counter == 3
        return arr.join(', ')
      end
    end
    qualifiers.select { |q| ! types.include?(q.qualifiable_type)}.each do |qualifier|
      counter +=1
      arr<< (qualifier.reversed? ? 'not ' : '') + qualifier.qualifiable.to_s
      if counter == 3
        return arr.join(', ')
      end
    end
    arr<< "Unread only" if unread_only?
    return arr.join(', ')
  end

  def to_include
    to_include = [ :project, :task_users]

    to_include << :tags if qualifiers.for("Tag").any?
    to_include << :task_property_values if qualifiers.for("PropertyValue").any?
    to_include << :customers if qualifiers.for("Customer").any?

    return to_include
  end

  def set_company_from_user
    self.company = user.company
  end

  # Returns a conditions hash the will filter tasks based on the
  # given property value qualifiers
  def conditions_for_property_qualifiers(property_qualifiers)
    property_qualifiers = property_qualifiers.group_by { |qualifier| qualifier.reversed? }
    simple_conditions_for_property_qualifiers(property_qualifiers[false]) + simple_conditions_for_property_qualifiers(property_qualifiers[true]).map { |sql| "not " + sql }
  end

  def simple_conditions_for_property_qualifiers(property_qualifiers)
    return [] if property_qualifiers.nil?
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
    standard_qualifiers = standard_qualifiers.group_by { |qualifier| qualifier.reversed?}
    simple_conditions_for_standard_qualifiers(standard_qualifiers[false])+ simple_conditions_for_standard_qualifiers(standard_qualifiers[true]).map{|sql| 'not ' + sql}
  end

  def simple_conditions_for_standard_qualifiers(standard_qualifiers)
    return [] if standard_qualifiers.nil?
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
    kws = keywords.group_by { |keyword| keyword.reversed? }
    compose_sql(simple_conditions_for_keywords(kws[false]), simple_conditions_for_keywords(kws[true]))
  end

  def simple_conditions_for_keywords(keywords_arg)
    return  if keywords_arg.nil?
    sql = []
    params = []

    keywords_arg.each do |kw|
      str = "lower(tasks.name) like ?"
      str += " or lower(tasks.description) like ?"
      sql << "coalesce((#{str}),0)"
      2.times { params << "%#{ kw.word.downcase }%" }
    end

    sql = sql.join(" or ")
    res = TaskFilter.send(:sanitize_sql_array, [ sql ] + params)
    return "(#{ res })" if !res.blank?
  end

  # Returns a sql string fragment that will limit tasks to only
  # status set by the status qualifiers.
  # Status qualifiers have to be handled especially until the
  # migration from an array in code to db backed statuses is complete
  def conditions_for_status_qualifiers(status_qualifiers)
    status_qualifiers = status_qualifiers.group_by { |qualifier| qualifier.reversed? }
    compose_sql(simple_conditions_for_status_qualifiers(status_qualifiers[false]), simple_conditions_for_status_qualifiers(status_qualifiers[true]))
  end

  def simple_conditions_for_status_qualifiers(status_qualifiers)
    return if status_qualifiers.nil?
    old_status_ids = []
    c = company || user.company

    status_qualifiers.each do |q|
      status = q.qualifiable
      old_status = c.statuses.index(status)
      old_status_ids << old_status
    end

    old_status_ids = old_status_ids.compact.join(",")
    return "tasks.status in (#{ old_status_ids })" if !old_status_ids.blank?
  end

  # Returns a sql string fragment that will limit tasks to only
  # those in a project belonging to customers, or linked directly
  # to the customer
  def conditions_for_customer_qualifiers(customer_qualifiers)
    customer_qualifiers = customer_qualifiers.group_by { |qualifier| qualifier.reversed? }
    compose_sql(simple_conditions_for_customer_qualifiers(customer_qualifiers[false]), simple_conditions_for_customer_qualifiers(customer_qualifiers[true]))
  end

  def simple_conditions_for_customer_qualifiers(customer_qualifiers)
    return if customer_qualifiers.nil?
    ids = customer_qualifiers.map { |q| q.qualifiable.id }
    ids = ids.join(",")

    if !ids.blank?
      res = "projects.customer_id in (#{ ids })"
      res += " or coalesce(task_customers.customer_id in (#{ ids }),0)"
      return "(#{ res })"
    end
  end

  # Returns a sql string fragment that will limit tasks to only those
  # which match the given time qualifiers
  def conditions_for_time_qualifiers(time_qualifiers)
    time_qualifiers = time_qualifiers.group_by { |qualifier| qualifier.reversed? }
    compose_sql(simple_conditions_for_time_qualifiers(time_qualifiers[false]), simple_conditions_for_time_qualifiers(time_qualifiers[true]))
  end

  def simple_conditions_for_time_qualifiers(time_qualifiers)
    return if time_qualifiers.nil? or time_qualifiers.empty?

    res = []
    time_qualifiers.each do |tq|
      start_time = tq.qualifiable.start_time
      end_time = tq.qualifiable.end_time
      column = tq.qualifiable_column
      column = Task.connection.quote_column_name(column)

      sql = "tasks.#{ column } >= '#{ start_time.to_formatted_s(:db) }'"
      sql += " and tasks.#{ column } < '#{ end_time.to_formatted_s(:db) }'"
      res << "coalesce((#{sql}),0)"
    end

    res = res.join(" or ")
    return "(#{ res })"
  end

  # Returns the column name to use for lookup for the given
  # class_type
  def column_name_for(class_type)
    if class_type == "User"
      return "task_users.type= 'TaskOwner' AND task_users.user_id"
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

  def unread_conditions(user, include_orphaned = false)
    count_conditions = []
    count_conditions << "(task_users.unread = ? and task_users.user_id = #{ user.id })"
    count_conditions << "(task_users.id is null)" if include_orphaned
    sql = count_conditions.join(" or ")

    params = [ true]
    sql = TaskFilter.send(:sanitize_sql_array, [ sql ] + params)
    "(#{ sql })"
  end

  def compose_sql(arg1, arg2)
    if arg1.blank?
      if arg2.blank?
        ""
      else
        "( not #{arg2} )"
      end
    else
      if arg2.blank?
        arg1
      else
        "(#{arg1} and not #{arg2})"
      end
    end
  end

  # Parse parameters from jqGrid for Task.all method
  # This function used to sort jqGrid created from tasks/list.xml.erb
  # many columns in jqGrid calculated in Task model or in tasks/list.xml.erb
  # following sort code duplicate logic from Task  and list.xml.erb in sql `order by`
  # TODO: Store all logic in sql view or create client side sorting.
  def parse_jqgrid_params(jqgrid_params)
    tasks_params={ }
    if !jqgrid_params[:rows].blank? and !jqgrid_params[:page].blank?
      tasks_params[:limit]=jqgrid_params[:rows].to_i > 0 ? jqgrid_params[:rows].to_i : 0
      tasks_params[:offset]=jqgrid_params[:page].to_i-1
      if tasks_params[:offset] >0
        tasks_params[:offset] *= tasks_params[:limit]
      else
        tasks_params[:offset]=nil
      end
    end
    case jqgrid_params[:sidx]
      when 'summary'
        tasks_params[:order]='tasks.name'
      when 'id'
        tasks_params[:order]='tasks.id'
      when 'due'
        tasks_params[:include]=[:milestone]
        tasks_params[:order]='(case isnull(tasks.due_at)  when 1 then milestones.due_at when 0  then tasks.due_at end)'
      when 'assigned'
        tasks_params[:order]='(select  group_concat(distinct users.name)  from  task_users  left outer join users on users.id = task_users.user_id where task_users.task_id=tasks.id  group by tasks.id)'
      when 'milestone'
        tasks_params[:order]="(select  CONCAT(projects.name, '/', if(isnull(milestones.name), '', milestones.name)) from tasks as ts inner join  projects on ts.project_id = projects.id left join milestones on ts.milestone_id = milestones.id where ts.id = tasks.id)"
      when 'client'
        tasks_params[:order]='if( exists(select  customers.name as client   from task_customers left outer join customers on task_customers.customer_id=customers.id where task_customers.task_id=tasks.id limit 1), (select  customers.name as client  from task_customers left outer join customers on task_customers.customer_id=customers.id where task_customers.task_id=tasks.id limit 1), (select customers.name from projects left outer join customers on projects.customer_id= customers.id where projects.id=tasks.project_id limit 1))'
      else
      if self.company.properties.collect{|p| p.name.downcase }.include?(jqgrid_params[:sidx])
        self.company.properties.each do|p|
          if p.name.downcase == jqgrid_params[:sidx]
            @property_id = p.id
            tasks_params[:order]= "(select property_values.position from  task_property_values, property_values where tasks.id=task_property_values.task_id and task_property_values.property_id=#{@property_id} and task_property_values.property_value_id = property_values.id)"
          end
        end
      else
        tasks_params[:order]=nil
      end
    end

    if !tasks_params[:order].nil?
      if (jqgrid_params[:sord] == 'desc')
        tasks_params[:order]+= ' desc'
      end
      if (jqgrid_params[:sord] == 'asc')
        #make sort null to bottom
        tasks_params[:order] = "#{tasks_params[:order]} is null, #{tasks_params[:order]}"
      end
    end
    return tasks_params
  end
  #This function parse fullCalendar `start` and `end` date(in Unix format) from  params
  #return conditions for TaskFilter#tasks, unfortunately TaskFilter#task does not support active record :conditions, only plain sql:(
  def parse_fullcalendar_params(calendar_params)
    if !calendar_params[:end].blank? and !calendar_params[:start].blank?
      return  "due_at< '#{Time.at(calendar_params[:end].to_i)}' and due_at > '#{Time.at(calendar_params[:start].to_i)}'"
    else
      return nil
    end
  end
end


# == Schema Information
#
# Table name: task_filters
#
#  id          :integer(4)      not null, primary key
#  name        :string(255)
#  company_id  :integer(4)
#  user_id     :integer(4)
#  shared      :boolean(1)
#  created_at  :datetime
#  updated_at  :datetime
#  system      :boolean(1)      default(FALSE)
#  unread_only :boolean(1)      default(FALSE)
#
# Indexes
#
#  fk_task_filters_user_id     (user_id)
#  fk_task_filters_company_id  (company_id)
#

