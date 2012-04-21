require "test_helper"

class ResourceAttributeTest < ActiveRecord::TestCase
  fixtures :companies

  def setup
    company = Company.find(:first)
    @type = company.resource_types.build(:name => "test")
    @type.new_type_attributes = [ { :name => "a1" }, { :name => "a2" } ]
    @type.save!

    @resource = company.resources.build(:name => "test res")
    @resource.resource_type = @type
  end

  def test_validation_regex_is_checked
    type_attr = @type.resource_type_attributes.first
    attr = ResourceAttribute.new
    attr.resource = @resource
    attr.resource_type_attribute = type_attr

    type_attr.validation_regex = ""
    assert attr.check_regex

    type_attr.validation_regex = "\\d"
    attr.value = "1"
    assert attr.check_regex
    attr.value = "a"
    assert !attr.check_regex
  end
end






# == Schema Information
#
# Table name: resource_attributes
#
#  id                         :integer(4)      not null, primary key
#  resource_id                :integer(4)
#  resource_type_attribute_id :integer(4)
#  value                      :string(255)
#  password                   :string(255)
#  created_at                 :datetime
#  updated_at                 :datetime
#
# Indexes
#
#  fk_resource_attributes_resource_id                 (resource_id)
#  fk_resource_attributes_resource_type_attribute_id  (resource_type_attribute_id)
#

