require "test_helper"

class CustomAttributeMethodsTests < ActiveRecord::TestCase
  fixtures :users, :companies

  def setup
    @company = Company.find(:first)
    
    args = { :attributable_type => "User", :display_name => "Test custom attr" }
    attr = @company.custom_attributes.create(args)
  end

  def test_available_custom_attributes_returns_expected
    attrs = User.new(:company => @company).available_custom_attributes
    assert_equal 1, attrs.length
    assert_equal "Test custom attr", attrs.first.display_name
  end

  def test_set_custom_attribute_values_creates_new_values
    attr = @company.custom_attributes.first
    user = users(:admin)
    
    args = [ { :custom_attribute_id => attr.id, :value => "Test value" } ]
    user.set_custom_attribute_values = args

    assert_equal 1, user.custom_attribute_values.length
    assert_equal "Test value", user.custom_attribute_values.first.value
  end

  def test_set_custom_attribute_values_removes_missing_values
    attr = @company.custom_attributes.first
    user = users(:admin)
    
    args = [ { :custom_attribute_id => attr.id, :value => "Test value 1" } ]
    args << { :custom_attribute_id => attr.id, :value => "Test value 2" }
    user.set_custom_attribute_values = args

    assert_equal 2, user.custom_attribute_values.length

    args = [ { :custom_attribute_id => attr.id, :value => "Test value 1" } ]
    user.set_custom_attribute_values = args

    assert_equal 1, user.custom_attribute_values.length
    assert_equal "Test value 1", user.custom_attribute_values.first.value
  end

end
