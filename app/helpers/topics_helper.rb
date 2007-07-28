module TopicsHelper
  def avatar_for(user, size=32)
    "<img src=\"#{user.avatar_url(size)}\" class=\"photo\" />"
  end

  def current_user
    session[:user]
  end

end
