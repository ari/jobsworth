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

    if type.is_password? and !attribute.value.blank?
      res = "<div class=\"password\"></div>"
      url = show_password_resource_path(@resource, :attr_id => attribute.id)
      res += link_to(_("Show password"), url)
    else
      res = text_field_tag("#{ name_prefix }[value]", attribute.value, 
                           :id => field_id, :class => "value")
    end

    if type.allows_multiple?
      add_style = show_remove_link ? "display: none" : ""
      remove_style = show_remove_link ? "" : "display: none;"

      res += link_to_function(_("Add"), "addAttribute(this)", 
                              :class => "add_attribute", 
                              :style => add_style)
      res += link_to_function(_("Remove"), "removeAttribute(this)", 
                              :class => "remove_attribute", 
                              :style => remove_style)
    end

    return res
  end

  ###
  # Returns only resources with no parent resource.
  ###
  def resources_without_parents(resources)
    resources.select { |r| r.parent.nil? }
  end
end
