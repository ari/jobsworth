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
  def value_field(attribute, name_prefix, field_id)
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
      res += link_to_function(_("Add"), "addAttribute(this)")
    end

    return res
  end
end
