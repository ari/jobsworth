module LoginHelper
  def signed_in_as(user)
    sign_in user # method from devise:TestHelpers
  end
end

module LoginRequestHelper
  def sign_in_as(user)
    post_via_redirect user_session_path, 'user[email]' => user.email, 'user[password]' => user.password
  end
end

module LoginFeatureHelpers
  def signed_in_as(user)
    login_as user, scope: :user
  end
end
