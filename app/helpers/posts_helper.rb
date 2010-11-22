# encoding: UTF-8
module PostsHelper
  def avatar_for(user, size=32)
    "<img src=\"#{user.avatar_url(size)}\" class=\"photo\" />".html_safe
  end
end
