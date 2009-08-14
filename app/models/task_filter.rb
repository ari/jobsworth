###
# A task filter is used to find tasks matching the filters set up
# in session.
###
class TaskFilter
  UNASSIGNED_TASKS = -1
  ALL_USERS = 0
  ALL_TASKS = 0
  ALL_MILESTONES = 0
  ALL_CUSTOMERS = 0
  ALL_PROJECTS = 0
  

  attr_accessor :session
  attr_accessor :current_user

  ###
  # Returns an array of user_ids which have been set as filters
  # in the given session.
  ###
  def self.filter_user_ids(session, unassigned_to_remove = nil)
    # When using views, session[:filter_user] will be an int.
    # When using filter selects, it will be an array.
    # We want it to always be an array, so convert it here:
    ids = filter_ids(session, :filter_user)
    ids.delete(unassigned_to_remove) if unassigned_to_remove
    return ids
  end

  ###
  # Returns an array of status ids which have been set as filters
  # in the given session.
  ###
  def self.filter_status_ids(session)
    return filter_ids(session, :filter_status)
  end

  ###
  # Returns an array of ids set as filter in the given session and name.
  # If passed, all_values_id_to_remove should be the value used to represent
  # all values for this filter, and will be removed from the returned list.
  ###
  def self.filter_ids(session, filter_name, all_values_id_to_remove = nil)
    ids = [ session[filter_name] ].flatten.compact
    ids = ids.map { |id| id.to_i }
    ids.delete(all_values_id_to_remove) if all_values_id_to_remove
    return ids
  end


  ###
  # Create a new task filter.
  #
  # controller should be the ActionController object that is using
  # this filter.
  #
  # Any relevant params will be used to further filter the 
  # returned tasks.
  ###
  def initialize(controller, params, extra_conditions = "")
    @current_user = controller.current_user
    @company = @current_user.company
    @params = params
    @session = controller.session
    @tz = controller.tz
    @completed_milestone_ids = controller.completed_milestone_ids
    @extra_conditions = extra_conditions
    @select_project_ids = current_user.projects.map { |p| p.id }.join(", ")
  end

  ###
  # Returns an array of tasks that match the currently set filters.
  ###
  def tasks
    if @tasks.nil?
      @tasks = tasks_by_filters
      @tasks = filter_by_tags(@tasks)
      @tasks += unread_tasks if session[:show_all_unread].to_i > 0
      @tasks = sort_tasks(@tasks)
    end

    return @tasks
  end

  ###
  # Returns tasks matching the filters set up in the current session.
  ###
  def tasks_by_filters
    to_include = [ :users, :tags, :sheets, :todos, :dependencies, 
                   :milestone, :notifications, :watchers, 
                   :customers ]
    to_include << { :work_logs => :user }
    to_include << { :company => :properties }
    to_include << { :project => :customer }
    to_include << { :task_property_values => { :property_value => :property } }
    to_include << { :dependants => [:users, :tags, :sheets, :todos, 
                                    { :project => :customer }, :milestone ] }

    conditions = filter
    conditions += " AND tasks.project_id in (#{ @select_project_ids })"
    conditions += " AND #{ @extra_conditions }" if !@extra_conditions.blank?

    Task.find(:all, 
              :conditions => [ conditions ],
              :include => to_include, 
              :limit => 250,
              :order => "tasks.id desc")
  end

  ###
  # Returns true if this object will be filtering tasks based on
  # tags.
  ###
  def filtering_by_tags?
    selected_tags
  end

  ###
  # Returns an array of any tags set that tasks have to match.
  ###
  def selected_tags
    if @params[:tag] && @params[:tag].strip.length > 0
      @selected_tags ||= @params[:tag].downcase.split(',').collect{ |t| t.strip }
    end

    return @selected_tags
  end

  ###
  # Returns a map of tags to their count in the current list. Only tags
  # with count > 0 will be included.
  ###
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

#  private

  ###
  # Returns a string to use in a find conditions param to only get
  # tasks matching the filters set in the session.
  ###
  def filter
    filter = ""

    filter = filter_by_user
    filter += filter_by_status
    filter += filter_by_milestones_projects_and_customers
    filter += filter_by_properties

    if session[:hide_deferred].to_i > 0
      filter << "(tasks.hide_until IS NULL OR tasks.hide_until < '#{@tz.now.utc.to_s(:db)}') AND "
    end 
    filter << "(tasks.milestone_id NOT IN (#{@completed_milestone_ids}) OR tasks.milestone_id IS NULL) AND "

    filter = filter.gsub(/( AND )$/, "")
    return filter
  end

  ###
  # Filter the given tasks by property values set in the session.
  ###
  def filter_by_properties
    res = []

    @company.properties.each do |prop|
      filter_value = session[prop.filter_name]
      filter_values = [ filter_value ].flatten.compact
      next if filter_values.empty?

      res << "task_property_values.property_value_id in (#{ filter_values.join(", ") })"
    end

    if res.any?
      return res.join(" AND ") + " AND "
    else
      return ""
    end
  end

  ###
  # Returns a string to use for filtering the task to display
  # based on the filter_milestone, filter_customer and filter_project
  # values in session.
  ###
  def filter_by_milestones_projects_and_customers
    res = []

    if milestone_ids.any? and !milestone_ids.include?(ALL_MILESTONES)
      res << "tasks.milestone_id IN (#{ milestone_ids.join(", ") })"
    end

    if customer_ids.any? and !customer_ids.include?(ALL_CUSTOMERS)
      res << "projects.customer_id IN (#{ customer_ids.join(", ") })"
    end

    if project_ids.any? and !project_ids.include?(ALL_PROJECTS)
      res << "tasks.project_id IN (#{ project_ids.join(", ") })"
    end

    if res.any?
      return "(#{ res.join(" OR ") }) AND "
    else
      return ""
    end
  end

  def customer_ids
    @customer_ids ||= TaskFilter.filter_ids(session, :filter_customer, ALL_CUSTOMERS)
  end

  def project_ids
    @project_ids ||= TaskFilter.filter_ids(session, :filter_project, ALL_PROJECTS)   
  end

  def milestone_ids
    @milestone_ids ||= TaskFilter.filter_ids(session, :filter_milestone, ALL_MILESTONES)
  end

  ###
  # Returns an array of tasks sorted according to the value
  # in the session.
  ### 
  def sort_tasks(tasks)
    sort_by = session[:sort].to_i
    res = tasks
        
    if sort_by == 0 # default sorting
      res = current_user.company.sort(tasks)
    elsif sort_by == 1
      res = tasks.sort_by{|t| [-t.completed_at.to_i, (t.due_date || 9999999999).to_i, - t.sort_rank,  -t.task_num] }
    elsif sort_by ==  2
      res = tasks.sort_by{|t| [-t.completed_at.to_i, t.created_at.to_i, - t.sort_rank,  -t.task_num] }
    elsif sort_by == 3
      res = tasks.sort_by{|t| [-t.completed_at.to_i, t.name.downcase, - t.sort_rank,  -t.task_num] }
    elsif sort_by ==  4
      res = tasks.sort_by{|t| [-t.completed_at.to_i, t.updated_at.to_i, - t.sort_rank,  -t.task_num] }.reverse
    end
        
    return res
  end

  ###
  # Returns a string to use for filtering the task to display
  # based on the filter_user value in session.
  ###
  def filter_by_user
    users = TaskFilter.filter_user_ids(session)
    return "" if users.empty? or users.include?(ALL_USERS)

    task_ids = []
    users.each do |id|
      if id > 0
        u = User.find(id)
        task_ids += u.tasks.map { |t| t.id }
      elsif id == UNASSIGNED_TASKS
        join = "LEFT OUTER JOIN task_owners t_o ON tasks.id = t_o.task_id"
        conditions = ["tasks.company_id = ? AND t_o.id IS NULL", @company.id ]
        unassigned =  Task.find(:all, :select => "tasks.*", 
                                :joins => join,
                                :readonly => false, 
                                :conditions => conditions)
        task_ids += unassigned.map { |t| t.id }
      end
    end

    task_ids = [ "0" ] if task_ids.empty?
    return "tasks.id IN (#{ task_ids.join(", ") }) AND "
  end

  ###
  # Returns a string to use for filtering the task to display
  # based on the filter_status value in session.
  ###
  def filter_by_status
    ids = TaskFilter.filter_status_ids(session)
    status_values = []
    hidden = "(tasks.hidden = 0 OR tasks.hidden IS NULL)"

    if ids.include?(0)
      status_values << "tasks.status = 0"
#      status_values << "tasks.status = 1"
      ids.delete(0)
    end
    if ids.include?(2)
      status_values << "tasks.status > 1"
      ids.delete(2)
    end
    if ids.include?(-2)
      hidden = "tasks.hidden = 1"
      ids.delete(-2)
    end
    if ids.include?(-1) # all statuses
      status_values.clear
      ids.delete(-1)
    end

    # the other values can be used untouched 
    status_values += ids.map { |id| "tasks.status = #{ id }" }
    status_values = status_values.join(" OR ")
    status_values = "(#{ status_values }) AND " if !status_values.blank?
    return "#{ status_values } (#{ hidden }) AND "
  end

  ###
  # Returns an array containing any tasks in the param
  # that have tags in selected_tags. If no tags are set, 
  # all tasks will be returned.
  ###
  def filter_by_tags(tasks)
    return tasks if !filtering_by_tags?

    res = []
    tasks.each do |task|
      selected_tags.each do |tag|
        res << task if task.has_tag?(tag)
      end
    end
    
    return res.uniq
  end

  ###
  # Returns all unread tasks for the current user.
  ###
  def unread_tasks
    notifications = current_user.notifications.unread
    notifications += current_user.task_owners.unread
    
    tasks = notifications.map { |n| n.task }
    tasks = tasks.uniq
    # only get open / in progress tasks
    tasks = tasks.select { |t| (t.status == 0 or t.status == 1) }

    return tasks
  end
end
