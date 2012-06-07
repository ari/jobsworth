require 'test_helper'

class ResetPasswordTest < ActionController::IntegrationTest
  should "an email in email_addresses table without user_id be invalid" do
    email = EmailAddress.make(:user_id => nil)
    visit "/users/password/new"
    fill_in "user_email", :with => email.email
    click_button "Send me reset email"
    assert page.has_content?("Invalid email!")
    assert current_path == "/users/password/new"
  end

  should "an email in email_addresses table with user_id be able to reset" do
    user = User.make
    email = EmailAddress.make(:user => user)

    visit "/users/password/new"
    fill_in "user_email", :with => email.email
    click_button "Send me reset email"

    assert current_path == "/users/sign_in"
  end
end
