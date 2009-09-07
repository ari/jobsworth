module TaskFilterHelper

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

  def link_to_remove_filter(filter_name, name, value, id)
    res = content_tag :span, :class => "search_filter" do
      hidden_field_tag("#{ filter_name }[]", id) +
        "#{ name }:#{ value }" + 
        link_to_function(image_tag("cross_small.png"), "removeSearchFilter(this)")
    end

    return res
  end

  # Return the html for a remote task filter form tag
  def remote_filter_form_tag
    form_remote_tag(:url => "/task_filters/update_current_filter", 
                    :html => { :method => "post", :id => "search_filter_form"},
                    :loading => "showProgress()",
                    :complete => "hideProgress(); Shadowbox.setup(); updateTooltips(); ",
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

  # Returns a link to set the task filter to show only open tasks.
  # If user is passed, only open tasks belonging to that user will 
  # be shown
  def link_to_open_tasks(user = nil)
    str = user ? _("My Open Tasks") : _("Open Tasks")
    open = current_user.company.statuses.first

    link_params = []
    link_params << { :qualifiable_type => "Status", :qualifiable_id => open.id }
    if user
      link_params << { :qualifiable_type => "User", :qualifiable_id => user.id }
    end
    link_params = { :task_filter => { :qualifiers_attributes => link_params } } 

    return link_to(str, update_current_filter_task_filters_path(link_params))
  end

  # Returns a link to set the task filter to show only in progress
  # tasks. Only tasks belonging to the given user will be shown.
  def link_to_in_progress_tasks(user)
    in_progress = current_user.company.statuses[1]

    link_params = []
    link_params << { :qualifiable_type => "Status", :qualifiable_id => in_progress.id }
    link_params << { :qualifiable_type => "User", :qualifiable_id => user.id }
    link_params = { :task_filter => { :qualifiers_attributes => link_params } } 

    return link_to(_("My In Progress Tasks"), 
                   update_current_filter_task_filters_path(link_params))
  end

  # Returns a link to allow the user to select the given
  # task filter
  def select_task_filter_link(filter)
    count = filter.display_count(current_user)

    str = h(filter.name)
    str += " (#{ count })" if count > 0
    class_name = (count > 0 ? "unread" : "")

    return link_to(str, select_task_filter_path(filter), :class => class_name)
  end

end
