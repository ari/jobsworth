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
    ids = [session[filter_name.to_sym] ].flatten.compact
    ids = ids.map { |id| id.to_i }
    ids.delete(all_values_id_to_remove) if all_values_id_to_remove
    return ids
  end


  ###
  # Returns an array of projects 
  ###
  def self.filter_projects(session)
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
    
    project_ids = TaskFilter.filter_ids(@session, :filter_project)
    if project_ids.include?(ALL_PROJECTS) or project_ids.empty?
      @project_ids = controller.current_project_ids
    else
      @project_ids = project_ids.join(", ")
    end

  end

  ###
  # Returns an array of tasks that match the currently set filters.
  ###
  def tasks
    if @tasks.nil?
      @tasks ||= (filtering_by_tags? ? tasks_by_tags : tasks_by_filters)
      @tasks = filter_by_properties(@tasks)
      @tasks = sort_tasks(@tasks)
    end

    return @tasks
  end

  ###
  # Returns tasks matching the tags in the params given
  # at construction.
  ###
  def tasks_by_tags
    Task.tagged_with(selected_tags, {
                       :company_id => @company.id,
                       :project_ids => @project_ids, 
                       :filter_hidden => session[:filter_hidden], 
                       :filter_user => session[:filter_user], 
                       :filter_milestone => session[:filter_milestone], 
                       :filter_status => session[:filter_status], 
                       :filter_customer => session[:filter_customer] 
                     })
  end

  ###
  # Returns tasks matching the filters set up in the current session.
  ###
  def tasks_by_filters
    to_include = [ :users, :tags, :sheets, :todos, :dependencies, :milestone ]
    to_include << { :company => :properties}
    to_include << { :project => :customer }
    to_include << { :task_property_values => { :property_value => :property } }
    to_include << { :dependants => [:users, :tags, :sheets, :todos, 
                                    { :project => :customer }, :milestone ] }

    conditions = "tasks.project_id IN (#{@project_ids}) AND " + filter
    conditions += " AND #{ @extra_conditions }" if !@extra_conditions.blank?

    Task.find(:all, 
              :conditions => [ conditions ],
              :include => to_include)
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

  private

  ###
  # Returns a string to use in a find conditions param to only get
  # tasks matching the filters set in the session.
  ###
  def filter
    filter = ""

    
    filter = filter_by_user
    filter << filter_by_milestone
    filter << filter_by_status
    filter << filter_by_customer

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
  def filter_by_properties(tasks)
    @company.properties.each do |prop|
      filter_value = session[prop.filter_name]
      filter_values = [ filter_value ].flatten.compact
      next if filter_values.empty?

      to_keep = []
      filter_values.each do |fv|
        to_keep += tasks.select do |t|
          val = t.property_value(prop)
          val and val.id == fv.to_i
        end
      end

      tasks = to_keep.uniq
    end

    return tasks
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
      status_values << "tasks.status = 1"
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

    # the other values can be used untouched 
    status_values += ids.map { |id| "tasks.status = #{ id }" }
    status_values = status_values.join(" OR ")
    status_values = "(#{ status_values }) AND " if !status_values.blank?
    return "#{ status_values } (#{ hidden }) AND "
  end

  ###
  # Returns a string to use for filtering the task to display
  # based on the filter_milestone value in session.
  ###
  def filter_by_milestone
    res = ""

    milestones = TaskFilter.filter_ids(session, :filter_milestone)
    if milestones.any? and !milestones.include?(ALL_MILESTONES)
      unassigned = milestones.delete_if { |id| id < 0 }
      filters = []
      if milestones.any?
        filters << "tasks.milestone_id in (#{ milestones.join(", ") }) "
      end
      
      unassigned.each do |id|
        project_id = -id + 1 # see note in application.rb#setup_task_filters
        filters << "tasks.project_id = project_id and (tasks.milestone_id is null or tasks.milestone_id = 0)"
      end
      
      res = filters.map { |f| "#{ f }" }.join(" OR ")
      res = "(#{ res }) AND " if !res.blank?
    end
    
    return res
  end

  ###
  # Returns a string to use for filtering the task to display
  # based on the filter_customer value in session.
  ###
  def filter_by_customer
    ids = TaskFilter.filter_ids(session, :filter_customer)
    return "" if ids.include?(ALL_CUSTOMERS) or ids.empty?

    project_ids = []
    ids.each do |id|
      customer = Customer.find(id)
      project_ids += customer.projects.map { |p| p.id }
    end

    if project_ids.empty?
      return ""
    else
      return "tasks.project_id IN (#{ project_ids.join(", ") }) AND "
    end
  end

end
