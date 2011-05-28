module UrlHelper

  # When devise sends emails (such as password resets), use the correct sub-domain
  def set_mailer_url_options
    ActionMailer::Base.default_url_options[:host] = with_subdomain(request.subdomain)
  end

end