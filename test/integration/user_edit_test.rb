require "test_helper"

class UserEditTest < ActionController::IntegrationTest
  context "a logged in user" do
    setup do
      @user = login
      @user.admin = true
      @user.save
      visit edit_user_path(@user)
    end

    should "be able to update user information" do
      @emails = @user.email_addresses
      @primary_email_id =  @emails.detect { |e| e.default }.id
      fill_in "emails[#{@primary_email_id}][email]", :with => "new@email.com"
      uncheck "Receive Notifications"
      click_button "Save"
      @user.reload

      assert_equal "new@email.com", @user.primary_email
      assert !@user.receive_notifications?
      assert_equal current_path, edit_user_path(@user)
      assert page.has_content?("User was successfully updated.")
    end
  end
end