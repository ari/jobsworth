module TopicsHelper
  def avatar_for(user, size=32)
    "<img src=\"#{user.avatar_url(size)}\" class=\"photo\" />".html_safe
  end

end
