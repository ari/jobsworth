# Signup emails

class Signup < ActionMailer::Base

  def signup(user, company, sent_at = Time.now)
    @subject    = '[Jobsworth] Account Registration'
    @body       = {:user => user, :company => company}
    @recipients = user.email
    @from       = "admin@#{$CONFIG[:domain]}"
    @sent_on    = sent_at
  end

  def forgot_password(user, sent_at = Time.now)
    @subject    = "[Jobsworth] #{user.company.name} Account Information"
    @body       = {:user => user}
    @recipients = user.email
    @from       = "admin@#{$CONFIG[:domain]}"
    @sent_on    = sent_at
  end

  def account_created(user, created_by, welcome_message, sent_at = Time.now)
    @subject    = "[Jobsworth] Invitation from #{created_by.name}"
    @body       = {:user => user, :created_by => created_by, :welcome_message => welcome_message}
    @recipients = user.email
    @from       = "admin@#{$CONFIG[:domain]}"
    @sent_on    = sent_at
    @reply_to   = created_by.email
  end

  def mass_email(user, sent_at = Time.now)
    @subject    = "[Jobsworth] New version"
    @body       = {:user => user}
    @recipients = user.email
    @from       = "admin@#{$CONFIG[:domain]}"
    @sent_on    = sent_at
  end

  def subdomain_changed(user, sent_at = Time.now)
    @subject    = "[Jobsworth] #{user.company.name} - Login URL changed"
    @body       = {:user => user}
    @recipients = user.email
    @from       = "admin@#{$CONFIG[:domain]}"
    @sent_on    = sent_at
  end


end
