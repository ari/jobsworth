# encoding: UTF-8
class CustomAttributeValue < ActiveRecord::Base
  belongs_to :custom_attribute
  belongs_to :attributable, :polymorphic => true
  belongs_to :choice, :class_name => "CustomAttributeChoice"
  validate :validate_custom_attribute

  def validate_custom_attribute
    valid = true
    max_length = custom_attribute.max_length

    has_value = (value and !value.blank?)
    has_value ||= choice

    if max_length and value and max_length < value.length
      errors.add(:base, "#{ custom_attribute.display_name } is too long")
      valid = false
    end

    if custom_attribute.mandatory? and !has_value
      errors.add(:base, "#{ custom_attribute.display_name } is required")
      valid = false
    end

    return valid
  end

  def to_s
    choice ? choice.value : value
  end
end







# == Schema Information
#
# Table name: custom_attribute_values
#
#  id                  :integer(4)      not null, primary key
#  custom_attribute_id :integer(4)
#  attributable_id     :integer(4)
#  attributable_type   :string(255)
#  value               :text
#  created_at          :datetime
#  updated_at          :datetime
#  choice_id           :integer(4)
#
# Indexes
#
#  by_attributables                                      (attributable_id,attributable_type)
#  index_custom_attribute_values_on_custom_attribute_id  (custom_attribute_id)
#

