class Signup < ActionMailer::Base

  def signup(user, company, sent_at = Time.now)
    @subject    = '[ClockingIT] Account Registration'
    @body       = {:user => user, :company => company}
    @recipients = user.email
    @from       = 'admin@clockingit.com'
    @sent_on    = sent_at
    @headers    = {}
  end

  def forgot_password(user, sent_at = Time.now)
    @subject    = "[ClockingIT] #{user.company.name} Account Information"
    @body       = {:user => user}
    @recipients = user.email
    @from       = 'admin@clockingit.com'
    @sent_on    = sent_at
    @headers    = {}
  end

  def account_created(user, created_by, sent_at = Time.now)
    @subject    = "[ClockingIT] Invitation from #{created_by.name}"
    @body       = {:user => user, :created_by => created_by}
    @recipients = user.email
    @from       = 'admin@clockingit.com'
    @sent_on    = sent_at
    @headers    = {}
  end

  def mass_email(user, sent_at = Time.now)
    @subject    = "[ClockingIT] New version"
    @body       = {:user => user}
    @recipients = user.email
    @from       = 'admin@clockingit.com'
    @sent_on    = sent_at
    @headers    = {}
  end

  def subdomain_changed(user, sent_at = Time.now)
    @subject    = "[ClockingIT] #{user.company.name} - Login URL changed"
    @body       = {:user => user}
    @recipients = user.email
    @from       = 'admin@clockingit.com'
    @sent_on    = sent_at
    @headers    = {}
  end
  

end
