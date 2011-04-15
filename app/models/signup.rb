# encoding: UTF-8
# Signup emails

class Signup < ActionMailer::Base

  self.default :from => "admin@#{$CONFIG[:domain]}"

  def signup(user, company, sent_at = Time.now)
    @user, @company = user, company

    mail(:subject => '[Jobsworth] Account Registration',
         :to => user.email,
         :date => sent_at
        )
  end

  def account_created(user, created_by, welcome_message, sent_at = Time.now)
    @user, @created_by, @welcome_message = user, created_by, welcome_message

    mail(:subject => "[Jobsworth] Invitation from #{created_by.name}",
         :to => user.email,
         :date => sent_at,
         :reply_to => created_by.email
        )    
  end

  def mass_email(user, sent_at = Time.now)
    @user = user

    mail(:subject => "[Jobsworth] New version",
         :to => user.email,
         :date => sent_at
        )
  end

  def subdomain_changed(user, sent_at = Time.now)
    @user = user

    mail(:subject => "[Jobsworth] #{user.company.name} - Login URL changed",
         :to => user.email,
         :date => sent_at
        )
  end


end
