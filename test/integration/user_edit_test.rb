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
      uncheck "Receive Notifications"
      click_button "Save"
      @user.reload

      assert !@user.receive_notifications?
      assert_equal current_path, edit_user_path(@user)
      assert page.has_content? I18n.t('flash.notice.model_updated', model: User.model_name.human)
    end
  end
end
