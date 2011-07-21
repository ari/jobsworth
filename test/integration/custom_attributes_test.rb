require 'test_helper'

class CustomAttributesTest < ActionController::IntegrationTest
  context "A logged in admin" do
    setup do
      @user = login
      @user.admin = true
      @user.save!
      @customer = @user.customer

      @params = {
        :attributable_type => "Customer",
        :display_name => "attr1",
        :position => 0
      }

      visit "/"
      visit "/customers"
    end

    context "with a basic custom attribute on customer" do
      setup do
        @attr = @user.company.custom_attributes.create(@params)
        click_link @customer.name
      end

      should "be able to edit custom attributes on customer edit screen" do
        fill_in @attr.display_name, :with => "attr1 value"
        click_button "Save"
        assert_equal "attr1 value", @customer.reload.values_for(@attr)[0]
      end
    end

    context "with a preset choice custom attribute" do
      setup do
        @attr = @user.company.custom_attributes.create(@params)
        @attr.custom_attribute_choices.create(:value => "Male")
        @attr.custom_attribute_choices.create(:value => "Female")
        click_link @customer.name
      end

      should "be able to edit custom attributes on customer edit screen" do
        select "Female", :from => @attr.display_name
        click_button "Save"
        assert_equal "Female", @customer.reload.values_for(@attr)[0]
      end
    end

    context "with a max length custom attribute" do
      setup do
        @attr = @user.company.custom_attributes.create(@params.merge(:max_length => 200))
        click_link @customer.name
      end

      should "be able to edit custom attributes on customer edit screen" do
        fill_in @attr.display_name, :with => "attr1 value"
        click_button "Save"
        assert_equal "attr1 value", @customer.reload.values_for(@attr)[0]
      end
    end
  end
end
