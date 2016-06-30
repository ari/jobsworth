require 'test_helper'

class ResetPasswordTest < ActionDispatch::IntegrationTest
  should 'an email in email_addresses table without user_id be invalid' do
    email = EmailAddress.make(:user_id => nil)
    visit new_user_password_path
    fill_in 'user_email', :with => email.email
    click_button 'Send me reset email'
    assert page.has_content?('Invalid email!')
    assert current_path == new_user_password_path
  end

  should 'an email in email_addresses table with user_id be able to reset' do
    user = User.make
    email = EmailAddress.make(:user => user)

    visit new_user_password_path
    fill_in 'user_email', :with => email.email
    click_button 'Send me reset email'

    assert current_path == new_user_session_path
  end
end
