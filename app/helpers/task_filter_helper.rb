module TaskFilterHelper

  ###
  # Initialises the instance variables needed to display the task
  # filter partial.
  ###
  def init_filter_variables
    customer_ids = TaskFilter.filter_ids(session, :filter_customer, TaskFilter::ALL_CUSTOMERS)
    if customer_ids.any?
      @all_projects = current_user.projects.find(:all, :conditions => ["customer_id in (#{ customer_ids.join(",") }) AND completed_at IS NULL"])
    else
      @all_projects = current_user.projects
    end

    project_ids = TaskFilter.filter_ids(session, :filter_project)
    if project_ids.any? and !project_ids.include?(TaskFilter::ALL_PROJECTS)
      projects = Project.find(:first, :order => "name", :conditions => [ "company_id = ? AND id in (?)", current_user.company_id, "#{ project_ids.join(",") }" ])
      @users = projects.users
    else
      @user_ids = ProjectPermission.find(:all, :conditions => ["project_id IN (?)", @all_projects.collect{|p| p.id}] ).collect{|pp| pp.user_id }.uniq
      @user_ids = [0] if @user_ids.size == 0
      @users = User.find(:all, :conditions => ["id IN (#{@user_ids.join(',')})"], :order => "name")
    end
  end

  ###
  # Returns the html to display a query menu for the items in names_and_ids.
  # Query menu elements can be clicked to add them to the task filter.
  # Options should contain one of:
  # :names_and_ids - an array of arrays like [ name, id ]
  # :collection - an array of objects that will be converted to names_and_ids
  ###
  def query_menu(name, names_and_ids)
    options = {}
    options[:filter_name] = name
    options[:names_and_ids] = names_and_ids

    return render(:partial => "/tasks/querymenu", :locals => options)
  end

  ###
  # Returns an array of names and ids
  ###
  def objects_to_names_and_ids(collection)
    return collection.map { |o| [ o.name, o.id ] }
  end

  ###
  # Returns the html to display the selected values in the current filter.
  ###
  def selected_filter_values(name, selected_names_and_ids)
    locals = {
      :selected_names_and_ids => selected_names_and_ids,
      :filter_name => name,
      :all_label => _("[Any #{ name.titleize }]"),
      :unassigned => TaskFilter::UNASSIGNED_TASKS
    }
    locals[:display_all_label] = (selected_names_and_ids.any? ? "none" : "")

    return render(:partial => "/tasks/selected_filter_values", :locals => locals)
  end

  ###
  # Returns an array containing the name and id of users currently
  # selected in the filter. Handles "unassigned" tasks too.
  ###
  def selected_user_names_and_ids
    res = TaskFilter.filter_user_ids(session).map do |id|
      if id == TaskFilter::UNASSIGNED_TASKS
        [ _("Unassigned"), id ]
      elsif id > 0
        user = current_user.company.users.find(id)
        [ user.name, id ]
      end
    end

    return res.compact
  end

  ###
  # Returns an array containing the name and id of statuses currently
  # selected in the filter. 
  ###
  def selected_status_names_and_ids
    selected = TaskFilter.filter_status_ids(session)
    return available_statuses.select do |name, id|
      selected.include?(id.to_i)
    end
  end
  
  ###
  # Returns an array of statuses that can be used to filter.
  ###
  def available_statuses
    statuses = []
    statuses << [_("Open"), "0"]
    statuses << [_("In Progress"), "1"]
    statuses << [_("Closed"), "2"]
    statuses << [_("Won't Fix"), "3"]
    statuses << [_("Invalid"), "4"]
    statuses << [_("Duplicate"), "5"]
    statuses << [_("Archived"), "-2"]

    return statuses
  end

end
