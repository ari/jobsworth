# encoding: UTF-8
# Signup emails

class Signup < ActionMailer::Base

  self.default :from => "admin@#{Setting.domain}"

  def signup(user, company, sent_at = Time.now)
    @user, @company = user, company

    mail(:subject => I18n.t("email.subject.signup"),
         :to => user.email,
         :date => sent_at
        )
  end

  def account_created(user, created_by, welcome_message, sent_at = Time.now)
    @user, @created_by, @welcome_message = user, created_by, welcome_message

    mail(:subject => I18n.t("email.subject.account_created", name: created_by.name),
         :to => user.email,
         :date => sent_at,
         :reply_to => created_by.email
        )
  end

  def mass_email(user, sent_at = Time.now)
    @user = user

    mail(:subject => I18n.t("email.subject.mass_email"),
         :to => user.email,
         :date => sent_at
        )
  end

  def subdomain_changed(user, sent_at = Time.now)
    @user = user

    mail(:subject => I18n.t("email.subject.subdomain_changed", company_name: user.company.name),
         :to => user.email,
         :date => sent_at
        )
  end


end
