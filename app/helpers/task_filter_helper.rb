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
  def query_menu(name, options = {})
    options[:filter_name] = name

    if (collection = options[:collection])
      options[:names_and_ids] = collection.map { |o| [ o.name, o.id ] }
    end

    return render(:partial => "/tasks/querymenu", :locals => options)
  end

end
