require File.dirname(__FILE__) + '/../test_helper'

class CustomAttributeValueTest < ActiveRecord::TestCase
  fixtures :users, :companies

  def setup
    @company = Company.find(:first)
    
    args = { :attributable_type => "User", :display_name => "Test custom attr" }
    @attr = @company.custom_attributes.create(args)
    @user = users(:admin)
  end

  def test_validate_checks_max_length
    @attr.max_length = 5
    @attr.save

    cav = CustomAttributeValue.new(:attributable_id => @user.id, 
                                   :attributable_type => "User",
                                   :custom_attribute_id => @attr.id)
    cav.value = "1234"
    assert cav.valid?

    cav.value = "12345"
    assert cav.valid?

    cav.value = "123456"
    assert !cav.valid?
    assert_equal "#{ @attr.display_name} is too long", cav.errors.first.last
  end

  def test_validate_checks_mandatory
    @attr.mandatory = true
    @attr.save

    cav = CustomAttributeValue.new(:attributable_id => @user.id, 
                                   :attributable_type => "User",
                                   :custom_attribute_id => @attr.id)

    cav.value = nil
    assert !cav.valid?

    cav.value = ""
    assert !cav.valid?

    cav.value = "something"
    assert cav.valid?

    # check with choice selected
    choice = @attr.custom_attribute_choices.build(:value => "test choice")
    choice.save!

    cav.value = nil
    cav.choice = choice
    assert cav.valid?
  end

end
