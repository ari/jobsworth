class CustomAttributeChoice < ActiveRecord::Base
  belongs_to :custom_attribute
  
  validates_presence_of :value
end

# == Schema Information
#
# Table name: custom_attribute_choices
#
#  id                  :integer(4)      not null, primary key
#  custom_attribute_id :integer(4)
#  value               :string(255)
#  position            :integer(4)
#  created_at          :datetime
#  updated_at          :datetime
#  color               :string(255)
#

