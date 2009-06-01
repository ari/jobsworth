class CustomAttributeValue < ActiveRecord::Base
  belongs_to :custom_attribute
  belongs_to :attributable, :polymorphic => true
  belongs_to :choice, :class_name => "CustomAttributeChoice"

  def validate
    valid = true
    max_length = custom_attribute.max_length

    if max_length and value and max_length < value.length
      errors.add_to_base("#{ custom_attribute.display_name } is too long")
      valid = false
    end

    if custom_attribute.mandatory? and (value.nil? or value.strip == "")
      errors.add_to_base("#{ custom_attribute.display_name } is required")
      valid = false
    end

    return valid
  end
end
