###
# A task filter is used to find tasks matching the filters set up
# in session.
###
class TaskFilter
  UNASSIGNED_TASKS = -1

  attr_accessor :session
  attr_accessor :current_user

  ###
  # Returns an array of user_ids which have been set as filters
  # in the given session.
  ###
  def self.filter_user_ids(session, include_unassigned = true)
    # When using views, session[:filter_user] will be an int.
    # When using filter selects, it will be an array.
    # We want it to always be an array, so convert it here:
    ids = [ session[:filter_user] ].flatten.compact
    ids = ids.map { |id| id.to_i }
    ids.delete(-1) if !include_unassigned
    return ids
  end

  ###
  # Returns an array of status ids which have been set as filters
  # in the given session.
  ###
  def self.filter_status_ids(session)
    ids = [ session[:filter_status] ].flatten.compact
    ids = ids.map { |id| id.to_i }
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
    
    if @session[:filter_project].to_i == 0
      @project_ids = controller.current_project_ids
    else
      @project_ids = @session[:filter_project]
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

    if session[:filter_milestone].to_i > 0
      filter << "tasks.milestone_id = #{session[:filter_milestone]} AND "
    elsif session[:filter_milestone].to_i < 0
      filter << "(tasks.milestone_id IS NULL OR tasks.milestone_id = 0) AND "
    end

    filter << filter_by_status

    if session[:hide_deferred].to_i > 0
      filter << "(tasks.hide_until IS NULL OR tasks.hide_until < '#{@tz.now.utc.to_s(:db)}') AND "
    end 

    unless session[:filter_customer].to_i == 0
      filter << "tasks.project_id IN (#{current_user.projects.find(:all, :conditions => ["customer_id = ?", session[:filter_customer]]).collect(&:id).compact.join(',') }) AND "
    end

    filter << "(tasks.milestone_id NOT IN (#{@completed_milestone_ids}) OR tasks.milestone_id IS NULL) "

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
    return "" if users.empty?

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
end
