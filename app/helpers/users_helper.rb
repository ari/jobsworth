module UsersHelper

  ###
  # Returns an image to show if the given user is online or offline.
  ###
  def user_online_image(user)
    if @user.online?
      return image_tag('status_online.png', :title => _('Online'), :class => 'tooltip')
    else
      return image_tag('status_offline.png', :title => _('Offline'), :class => 'tooltip')
    end
  end

end
