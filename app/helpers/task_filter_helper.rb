# encoding: UTF-8
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

  def link_to_remove_filter(filter_name, name, value, id)
    res = content_tag :span, :class => "search_filter" do
      hidden_field_tag("#{ filter_name }[]", id) +
        "#{ name }:#{ value }" +
        link_to_function('<i class="icon-remove"></i>'.html_safe, "removeSearchFilter(this)")
    end

    return res
  end

  # Returns a link to set the task filter to show only open tasks.
  # If user is passed, only open tasks belonging to that user will
  # be shown
  def link_to_open_tasks(user = nil)
    str = user ? _("My Open Tasks") : _("Open Tasks")
    open = current_user.company.statuses.first
    return link_to(str, path_to_tasks_filtered_by(open, user))
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
    name = if qualifier.qualifiable_type == "PropertyValue"
      qualifier.qualifiable.property.name
    elsif qualifier.qualifiable_type == "TimeRange"
      qualifier.qualifiable_column.gsub("_at", "").humanize
    elsif qualifier.qualifiable_type == "Status"
      "Resolution" #FIXME: would be better use Status.to_s or something like this
    else
      qualifier.qualifiable_type
    end
    name += ' is not' if qualifier.reversed?
    return name
  end

  # Returns the value of the given qualifier
  def qualifier_value(qualifier)
    if qualifier.qualifiable_type == "PropertyValue"
      return qualifier.qualifiable.value
    else
      # FIXME the next line is a bit rubbish: all qualifiable should have 'value'
      return qualifier.qualifiable.to_s
    end
  end

  def link_to_tasks_filtered_by(*args)
    name= args.first.is_a?(String) ? args.shift : args.first.name
    object= args.first
    html_options=args.second
    open = current_user.company.statuses.first
    return link_to(h(name), path_to_tasks_filtered_by(open, object), html_options)
  end

  def path_to_tasks_filtered_by(*objects)
    link_params = { :task_filter => { :qualifiers_attributes =>objects.compact.collect{ |object| { :qualifiable_type => object.class, :qualifiable_id => object.id } } } }
    update_current_filter_task_filters_path(link_params)
  end

  def link_to_toggle_status(tf, user)
    tf.show?(user) ? link_to("Hide", "#", :class => "action_filter do_hide") : link_to("Show", "#", :class => "action_filter do_show")
  end

end
