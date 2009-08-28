require 'test_helper'

class EditPreferencesTest < ActionController::IntegrationTest
  context "a logged in user" do
    setup do 
      @user = login
      click_link "preferences"
    end

    should "be able to edit their own preferences" do
      fill_in "email", :with => "new@email.com"
      uncheck "receive notifications by default"
      click_button "save"
      @user.reload

      assert_equal "new@email.com", @user.email
      assert !@user.receive_notifications?
    end

    context "with custom attributes on user" do
      setup do
        company = @user.company
        @attr = company.custom_attributes.build(:attributable_type => "User", :display_name => "attr1")
        @attr.save!

        # need to reload so custom attrs show up
        click_link "preferences"
      end

      should "be able to edit their own custom attributes" do
        fill_in @attr.display_name, :with => "attr1 value"
        click_button "save"
        assert_equal @user.reload.values_for(@attr).first, "attr1 value"
      end
    end
  end
end
