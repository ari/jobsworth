class PasswordsController < Devise::PasswordsController
  layout false

  def create
    email=EmailAddress.find_by_email(params[resource_name][:email])
    if email
    user=User.find(email.user_id)
    self.resource = user.send_reset_password_instructions#(:email => email.email)
    else
      flash[:error]="Invalid email!"
      redirect_to new_user_password_path
      return
    end
    if resource.errors.empty?
      set_flash_message :notice, :send_instructions
      redirect_to new_session_path(resource_name)
    else
      render_with_scope :new
    end
  end
end
