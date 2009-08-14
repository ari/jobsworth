module TaskFilterHelper

  ###
  # Initialises the instance variables needed to display the task
  # filter partial.
  ###
  def init_filter_variables(locals)
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

    hide_display_options = locals[:hide_display_options]
    if hide_display_options
      @task_only_option_style = "display: none;" 
    end
  end

  ###
  # Returns the html to display a query menu for the items in names_and_ids.
  # Query menu elements can be clicked to add them to the task filter.
  # If label is passed, that will be used as the label for the menu. If that is
  # not passed, a pretty version of name will be used instead.
  ###
  def query_menu(name, names_and_ids, label = nil, &block)
    options = {}
    options[:label] = label || name.gsub(/filter_/, "").pluralize.titleize
    options[:filter_name] = name
    options[:names_and_ids] = names_and_ids
    options[:callback] = block

    return render(:partial => "/tasks/querymenu", :locals => options)
  end

  ###
  # Returns an array of names and ids
  ###
  def objects_to_names_and_ids(collection, options = {})
    defaults = { :name_method => :name }
    options = defaults.merge(options)

    return collection.map do |o| 
      name = o.send(options[:name_method])
      id = o.id
      id = "#{ options[:prefix] }#{ id }" if options[:prefix]

      [ name, id ]
    end
  end

  ###
  # Returns the html to display the selected values in the current filter.
  ###
  def selected_filter_values(name, selected_names_and_ids, label = nil, default_label_text = "Any", &block)
    label ||= name.gsub(/^filter_/, "").titleize
    selected_names_and_ids ||= []

    locals = {
      :selected_names_and_ids => selected_names_and_ids,
      :filter_name => name,
      :all_label => _("[#{ default_label_text } %s]", label),
      :unassigned => TaskFilter::UNASSIGNED_TASKS
    }
    locals[:display_all_label] = (selected_names_and_ids.any? ? "none" : "")

    return render(:partial => "/tasks/selected_filter_values", :locals => locals, &block)
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

  ###
  # Returns the html to display the filters to select customers, projects
  # and milestones.
  # The list of currently selected filters will be included in the return value.
  ###
  def customer_project_and_milestones_query_menus
    selected = []

    customer_ids = TaskFilter.filter_ids(session, :filter_customer)
    milestone_ids = TaskFilter.filter_ids(session, :filter_milestone)
    project_ids = TaskFilter.filter_ids(session, :filter_project)

    # need to eager load customers and milestones, so using custom finder here 
    proj_permissions = current_user.project_permissions.all(:include => { :project => [ :customer, :milestones ] })
    projects = proj_permissions.map { |pp| pp.project }.uniq
    selected += selected_filters_for(:project, projects)

    customers = projects.map { |p| p.customer }.uniq
    customers = customers.sort_by { |c| c.name.downcase }
    selected += selected_filters_for(:customer, customers)

    milestones = projects.inject([]) { |array, project| array += project.milestones }
    selected += selected_filters_for(:milestone, milestones)
    
    values = objects_to_names_and_ids(customers, :prefix => "c")

    res = query_menu("filter", values, _("Clients/Projects")) do |customer_id|
      customer_id = customer_id[1, customer_id.length]
      projects = current_user.projects.find(:all, :conditions => { 
                                              :customer_id => customer_id })
      add_filter_html(filter_values_for_projects(projects), "filter")
    end

    res += selected_filter_values("filter", selected, _("Client/Project"))

    return res
  end

  ###
  # Returns the filter links for the given projects. Milestones are
  # also included.
  ###
  def filter_values_for_projects(projects)
    res = []

    projects.each do |project|
      res << [ project.name, "p#{ project.id }" ]
      project.milestones.each do |milestone|
        res << [ "- #{ milestone.name }", "m#{ milestone.id }" ]
      end
    end

    return res
  end

  ###
  # Returns the html to list the links to add filters to the current filter.
  ###
  def add_filter_html(names_and_ids, filter_name, callback = nil, &block)
    res = []
    callback ||= block

    names_and_ids.each do |name, id|
      content = link_to_function(name, "addTaskFilter(this, '#{ id }', '#{ filter_name }[]')")
      content += callback.call(id) if callback
      classname = "add"
      classname += " first" if res.empty?
      res << content_tag(:li, content, :class => classname)
    end

    content = res.join(" ")
    return content_tag(:ul, content, :class => "menu")
  end

  ###
  # Returns an array of [ name, id ] pairs that are set in the current
  # session filter for the given type.
  ###
  def selected_filters_for(type, collection)
    prefix = type.to_s[0, 1]
    ids = TaskFilter.filter_ids(session, "filter_#{ type }".to_sym)
    
    selected = collection.select { |o| ids.include?(o.id) }
    return objects_to_names_and_ids(selected, :prefix => prefix)
  end

  ###
  # Returns the possible values for sorting tasks by.
  ###
  def sort_options
    options = []
    options << [_("Due Date"), "1"]
    options << [_("Age"), "2"]
    options << [_("Name"), "3"]
    options << [_("Recent"), "4"]

    return options
  end

  ###
  # Returns the possible values for grouping tasks by.
  ###
  def group_by_options
     options = [
                [_("Tags"), "1"],
                [_("Clients"), "2"],
                [_("Projects"), "3"],
                [_("Milestones"), "4"],
                [_("Projects / Milestones"), "10"],
                [_("Users"), "5"],
                [_("Status"), "7"], 
                [_("Requested By"), "11"]
               ]

    current_user.company.properties.each do |prop|
      options << [ prop.name, prop.filter_name ]
    end

    return options
  end

  def show_filter_legend?
    return controller_name == "reports"
  end

  # Returns an array of all the currently set filters.
  # Each element in the array is a 3 element array with: 
  # [ filter_type, filter_value, filter_id ], for example:
  # [ "project", "project 2", "p3" ]
  def all_current_filters
    res = []

    # need to eager load customers and milestones, so using custom finder here 
    proj_permissions = current_user.project_permissions.all(:include => { :project => [ :customer, :milestones ] })
    projects = proj_permissions.map { |pp| pp.project }.uniq
    selected_filters_for(:project, projects).each do |value, id|
      res << link_to_remove_filter(:filter, _("Project"), value, id)
    end

    customers = projects.map { |p| p.customer }.uniq
    customers = customers.sort_by { |c| c.name.downcase }
    selected_filters_for(:customer, customers).each do |value, id|
      res << link_to_remove_filter(:filter, _("Client"), value, id)
    end

    milestones = projects.inject([]) { |array, project| array += project.milestones }
    selected_filters_for(:milestone, milestones).each do |value, id|
      res << link_to_remove_filter(:filter, _("Milestone"), value, id)
    end

    selected_status_names_and_ids.each do |value, id|
      res << link_to_remove_filter(:filter_status, _("Status"), value, id)
    end

    selected_user_names_and_ids.each do |value, id|
      res << link_to_remove_filter(:filter_user, _("User"), value, id)
    end

    current_user.company.properties.each do |property|
      filter_name = property.filter_name
      filter_ids = TaskFilter.filter_ids(session, filter_name)
      values = property.property_values
      selected = values.select { |pv| filter_ids.include?(pv.id) }
      objects_to_names_and_ids(selected, :name_method => :value).each do |value, id|
        res << link_to_remove_filter(filter_name, property.name, value, id)
      end
    end

    return res
  end

  def link_to_remove_filter(filter_name, name, value, id)
    res = content_tag :span, :class => "search_filter" do
      hidden_field_tag("#{ filter_name }[]", id) +
        "#{ name }:#{ value }" + 
        link_to_function(image_tag("cross_small.png"), "removeSearchFilter(this)")
    end

    return res
  end

  # Return the html for a remote task filter form tag
  def remote_filter_tag
    form_remote_tag(:url => "setup_task_filters", 
                    :html => { :method => "post", :id => "search_filter_form"},
                    :loading => "showProgress()",
                    :complete => "hideProgress()",
                    :update => "#content")
  end

  # Returns the html/js to make any tables matching selector sortable
  def sortable_table(selector, default_sort)
    column, direction = (default_sort || "").split("_")

    res = javascript_include_tag "jquery.tablesorter.min.js"
    js = <<-EOS
           makeSortable(jQuery("#{ selector }"), "#{ column }", "#{ direction }");
           jQuery("#{ selector }").bind("sortEnd", saveSortParams);
EOS
    res += javascript_tag(js, :defer => "defer")
    return res
  end

end
