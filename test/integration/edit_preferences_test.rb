require "test_helper"

class EditPreferencesTest < ActionController::IntegrationTest
  context "a logged in user" do
    setup do
      @user = login
      visit edit_user_path(@user)
    end

    should "be able to edit their own preferences" do
      uncheck "Receive Notifications"
      click_button "Save"
      @user.reload

      assert !@user.receive_notifications?
    end

    context "with custom attributes on user" do
      setup do
        company = @user.company
        @attr = company.custom_attributes.build(:attributable_type => "User", :display_name => "attr1")
        @attr.save!

        # need to reload so custom attrs show up
        visit edit_user_path(@user)
      end

      should "be able to edit their own custom attributes" do
        fill_in @attr.display_name, :with => "attr1 value"
        click_button "Save"
        assert_equal @user.reload.values_for(@attr).first, "attr1 value"
      end
    end
  end
end
