# encoding: UTF-8
class ResourceTypeAttribute < ActiveRecord::Base
  belongs_to :resource_type
  acts_as_list :scope => :resource_type

  validates_presence_of :name
end






# == Schema Information
#
# Table name: resource_type_attributes
#
#  id                   :integer(4)      not null, primary key
#  resource_type_id     :integer(4)
#  name                 :string(255)
#  is_mandatory         :boolean(1)
#  allows_multiple      :boolean(1)
#  is_password          :boolean(1)
#  validation_regex     :string(255)
#  default_field_length :integer(4)
#  position             :integer(4)
#  created_at           :datetime
#  updated_at           :datetime
#
# Indexes
#
#  fk_resource_type_attributes_resource_type_id  (resource_type_id)
#

