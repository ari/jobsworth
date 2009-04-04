class ResourceAttribute < ActiveRecord::Base
  belongs_to :resource
  belongs_to :resource_type_attribute

  include ERB::Util

  ###
  # If a validation regex is setup, checks the value matches
  # that regex. Returns if it does, or if validation_regex.blank?
  # Ideally this would be a validation, but I'm having trouble
  # getting that working (BW)
  ###
  def check_regex
    return true if resource_type_attribute.nil?

    regex = resource_type_attribute.validation_regex
    res = true
    if !regex.blank? and !value.blank?
      res = value.match(regex)
    end

    return res
  end

  ###
  # Returns any unsaved changes to this attribute as array of
  # printable html strings.
  ###
  def changes_as_html
    res = []
    type = resource_type_attribute

    self.changes.each do |name, values|
      # we don't care if the id changes, only value
      next if name !="value"
      
      old_value = values[0]
      new_value = values[1]
      
      str = "<strong>#{ h(type.name.humanize) }</strong>: "
      str += "#{ h(old_value) }"
      if type.is_password?
        str += " changed to a new password."
      else
        str += " -> #{ h(new_value) }"
      end
      
      res << str
    end
    
    return res
  end

end
