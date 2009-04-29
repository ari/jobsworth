require File.dirname(__FILE__) + '/../test_helper'

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
