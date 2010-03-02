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
  def remote_filter_form_tag(&block)
    args={ :url => "/task_filters/update_current_filter",
                    :html => { :method => "post", :id => "search_filter_form"},
                    :loading => "showProgress()",
                    :update => "search_filter_keys",
                    :loaded => "tasklistReload(); hideProgress() "}
    if block_given?
      return form_remote_tag(args, &block)
    else
      return form_remote_tag(args)
    end
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

  def link_to_unread_tasks(user)
    label = _("My Unread Tasks")
    link_params = { :task_filter => {
        :unread_only => true } }

    count = TaskFilter.new(:user => current_user, :unread_only => true).count
    if count > 0
      class_name = "unread"
      label = _("#{ label } (%s)", count)
    end

    return link_to(label,
                   update_current_filter_task_filters_path(link_params),
                   :class => class_name)
  end

  # Returns a link to allow the user to select the given
  # task filter
  def select_task_filter_link(filter)
    count = filter.display_count(current_user)

    str = h(filter.name)
    str += " (#{ count })" if count > 0
    class_name = (count > 0 ? "unread" : "")

    return link_to(str, { :controller => 'task_filters', :action => 'select', :id => filter.id})
  end

  # Returns the name to print out to describe the type of the
  # given qualifier
  def qualifier_name(qualifier)
    if qualifier.qualifiable_type == "PropertyValue"
      return qualifier.qualifiable.property.name
    elsif qualifier.qualifiable_type == "TimeRange"
      return qualifier.qualifiable_column.gsub("_at", "").humanize
    elsif qualifier.qualifiable_type == "Status"
      return "Resolution" #FIXME: would be better use Status.to_s or something like this
    else
      qualifier.qualifiable_type
    end
  end

end
