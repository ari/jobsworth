class ResourceAttribute < ActiveRecord::Base
  belongs_to :resource
  belongs_to :resource_type_attribute

  def validate
    return true if resource_type_attribute.nil?

    regex = resource_type_attribute.validation_regex
    valid = true
    if !regex.blank?
      valid = value.match(regex)
      errors.add("value", "Doesn't match regex") if !valid
    end

    return valid
  end
end
