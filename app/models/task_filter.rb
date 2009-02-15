###
# A task filter is used to find tasks matching the filters set up
# in session.
###
class TaskFilter
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
      if filtering_by_tags?
        @tasks = tasks_by_tags
      end
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
                       :filter_hidden => @session[:filter_hidden], 
                       :filter_user => @session[:filter_user], 
                       :filter_milestone => @session[:filter_milestone], 
                       :filter_status => @session[:filter_status], 
                       :filter_customer => @session[:filter_customer] 
                     })
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

end
