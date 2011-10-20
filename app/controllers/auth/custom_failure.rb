class Auth::CustomFailure < Devise::FailureApp

  # Never do http authentication through Devise

  # Not sure if this right here it's doing anything...
  # since we already disabled http authentication using
  # config.http_authenticatable = false
  def http_auth?
    false
  end

  def redirect_url
    send(:"new_#{scope}_session_path", :format => (request.xhr? ? 'js' : nil ))
  end
  
  def redirect
    if request.xhr? || request.format == 'text/javascript'
      redirect_to new_user_session_path, :status => 401
    else
      super
    end
  end
end
