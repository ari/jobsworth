# encoding: UTF-8
module ResourcesHelper
  ###
  # Returns an array that can be used to select what the
  # type of a resource is.
  ###
  def resource_types_options_array
    current_user.company.resource_types.map { |rt| [rt.name, rt.id] }
  end

  ###
  # Returns the html to display the value for attribute.
  # If it is a password field, adds a link to request the
  # unencrypted password.
  ###
  def value_field(attribute, name_prefix, field_id, show_remove_link = false)
    type = attribute.resource_type_attribute
    value = attribute.value
    if attribute.new_record? and type.is_password?
      value = _("User")
    end

    res = text_field_tag("#{ name_prefix }[value]", value, 
                         :id => field_id, :class => "value", 
                         :size => type.default_field_length)

    if type.is_password?
      res += resource_password_field(attribute, type, name_prefix, field_id)
    end

    if type.allows_multiple?
      add_style = show_remove_link ? "display: none" : ""
      remove_style = show_remove_link ? "" : "display: none;"

      res += link_to_function(_("Add another"), "addAttribute(this)", 
                              :class => "add_attribute", 
                              :style => add_style)
      res += link_to_function(_("Remove"), "removeAttribute(this)", 
                              :class => "remove_attribute", 
                              :style => remove_style)
    end

    return res
  end

  def resource_password_field(attribute, type, name_prefix, field_id)
    res = ""
    if attribute.new_record? or attribute.password.blank?
      res = text_field_tag("#{ name_prefix }[password]", "Password",
                           :id => field_id, :class => "password", 
                           :size => type.default_field_length)
    else 
      res = "<div class=\"password\"></div>"
      url = show_password_resource_path(@resource, :attr_id => attribute.id)
      res += link_to_function(_("Show Password"), "showPassword(this, '#{ url }')")
    end

    return res.html_safe
  end

  ###
  # Returns only resources with no parent resource.
  ###
  def resources_without_parents(resources)
    resources.select do |r| 
      r.parent.nil? or !resources.include?(r.parent)
    end
  end

  ###
  # Returns all child resources of resource that should be shown.
  ###
  def child_resources(resource, all_visible_resources)
    resource.child_resources.select { |r| all_visible_resources.include?(r) }
  end

  ###
  # Returns the html to use to filter by resource types.
  ###
  def resource_type_filter
    return filter_for(:resource_type_id, 
                      objects_to_names_and_ids(current_user.company.resource_types),
                      session[:resource_filters], _("Resource Type"))
  end

  ###
  # Returns the html to use to filter by customers
  ###
  def customer_filter
    customers = current_user.company.resources.map { |r| r.customer }
    customers = customers.compact.uniq.sort_by { |c| c.name.downcase }

    return filter_for(:customer_id, objects_to_names_and_ids(customers),
                      session[:resource_filters], _("Customer"))
  end

  ###
  # Returns the html to display the given event log occured on.
  # If this is just the same as the last used date, returns nil.
  ###
  def history_date_if_needed(log)
    date = tz.utc_to_local(log.updated_at).strftime("%A, %d %B %Y") 
    if date != @last_date
      res = content_tag(:div, date, :class => "log_header")
      @last_date = date
    end

    return res
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

    return render(:partial => "/resources/querymenu", :locals => options)
  end

  # Returns the html to list the links to add filters to the current filter.
  def add_filter_html(names_and_ids, filter_name, callback = nil, &block)
    res = []
    callback ||= block

    names_and_ids.each do |name, id|
      content = link_to_function(name, "addTaskFilter(this, '#{ id }', '#{ filter_name }[]')")
      content += callback.call(id) if callback
      classname = "add"
      classname += " first" if res.empty?
      res << content_tag(:li, content.html_safe, :class => classname)
    end

    content = res.join(" ").html_safe
    return content_tag(:ul, content, :class => "menu")
  end

  # Returns the html to display the selected values in the current filter.
  def selected_filter_values(name, selected_names_and_ids, label = nil, default_label_text = "Any", &block)
    label ||= name.gsub(/^filter_/, "").titleize
    selected_names_and_ids ||= []

    locals = {
      :selected_names_and_ids => selected_names_and_ids,
      :filter_name => name,
      :all_label => _("[#{ default_label_text } %s]", label),
      :unassigned => 0
    }
    locals[:display_all_label] = (selected_names_and_ids.any? ? "none" : "")

    return render(:partial => "/resources/selected_filter_values", :locals => locals, &block)
  end


end
