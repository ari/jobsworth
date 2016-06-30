class Auth::PasswordsController < Devise::PasswordsController
  layout 'blank'

  def create
    email= EmailAddress.where('user_id IS NOT NULL').find_by(:email => params[resource_name][:email])

    if email
      self.resource = email.user
      resource.send_reset_password_instructions
    else
      flash[:error]='Invalid email!'
      redirect_to new_user_password_path
      return
    end

    if resource.errors.empty?
      set_flash_message :success, :send_instructions
      redirect_to new_session_path(resource_name)
    else
      render_with_scope :new
    end
  end
end
