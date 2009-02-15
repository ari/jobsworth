###
# A task filter is used to find tasks matching the filters set up
# in session.
###
class TaskFilter
  attr_accessor :session
  attr_accessor :current_user

  ###
  # Create a new task filter.
  #
  # controller should be the ActionController object that is using
  # this filter.
  #
  # Any relevant params will be used to further filter the 
  # returned tasks.
  ###
  def initialize(controller, params = {})
    @current_user = controller.current_user
    @company = @current_user.company
    @params = params
    @session = controller.session
    @tz = controller.tz
    @completed_milestone_ids = controller.completed_milestone_ids
    
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

    conditions = [ "tasks.project_id IN (#{@project_ids}) AND " + filter ]

    Task.find(:all, 
              :conditions => conditions,
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

    if session[:filter_user].to_i > 0
      task_ids = User.find(session[:filter_user].to_i).tasks.collect { |t| t.id }.join(',')
      if task_ids == ''
        filter = "tasks.id IN (0) AND "
      else
        filter = "tasks.id IN (#{task_ids}) AND "
      end
    elsif session[:filter_user].to_i < 0
      not_task_ids = Task.find(:all, :select => "tasks.*", :joins => "LEFT OUTER JOIN task_owners t_o ON tasks.id = t_o.task_id", :readonly => false, :conditions => ["tasks.company_id = ? AND t_o.id IS NULL", current_user.company_id]).collect { |t| t.id }.join(',')
      if not_task_ids == ''
        filter = "tasks.id = 0 AND "
      else
        filter = "tasks.id IN (#{not_task_ids}) AND " if not_task_ids != ""
      end
    end

    if session[:filter_milestone].to_i > 0
      filter << "tasks.milestone_id = #{session[:filter_milestone]} AND "
    elsif session[:filter_milestone].to_i < 0
      filter << "(tasks.milestone_id IS NULL OR tasks.milestone_id = 0) AND "
    end

    unless session[:filter_status].to_i == -1 || session[:filter_status].to_i == -2
      if session[:filter_status].to_i == 0
        filter << "(tasks.status = 0 OR tasks.status = 1) AND "
      elsif session[:filter_status].to_i == 2
        filter << "(tasks.status > 1) AND "
      else
        filter << "tasks.status = #{session[:filter_status].to_i} AND "
      end
    end

    if session[:filter_status].to_i == -2
      filter << "tasks.hidden = 1 AND "
    else
      filter << "tasks.hidden = 0 AND "
    end

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

      if filter_value.to_i > 0
        tasks = tasks.delete_if do |t| 
          val = t.property_value(prop)
          val.nil? or val.id != filter_value.to_i
        end
      end
    end

    return tasks
  end

end
