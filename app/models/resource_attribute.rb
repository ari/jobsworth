class ResourceAttribute < ActiveRecord::Base
  belongs_to :resource
  belongs_to :resource_type_attribute

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
end
