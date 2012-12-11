#encoding: UTF-8

$CONFIG = {
  # The client specific hostname will be prepended to this domain
  :domain => $servlet_context.getInitParameter("config.domain"),  
  :email_domain => $servlet_context.getInitParameter("config.email_domain"),
  # Note that this is not a full email address, just the part before the @
  :replyto => $servlet_context.getInitParameter("config.replyto"),  
  # Note that this is not a full email address, just the part before the @
  :from => $servlet_context.getInitParameter("config.from"),  
  :prefix => $servlet_context.getInitParameter("config.prefix"),
  :productName => $servlet_context.getInitParameter("config.productName"),
  :SSL => $servlet_context.getInitParameter("config.ssl"),
  :store_root => Rails.root.join($servlet_context.getInitParameter("config.storeroot")).to_s
}

ActionMailer::Base.smtp_settings = {
  :address  => $servlet_context.getInitParameter("smtp.host"),
  :port  => $servlet_context.getInitParameter("smtp.port"),
  :domain  => $servlet_context.getInitParameter("smtp.domain")
}

# Setup email notification of errors
Jobsworth::Application.config.middleware.use ExceptionNotifier,
  :email_prefix => $servlet_context.getInitParameter("jobsworth.error.email_prefix"),
  :sender_address => $servlet_context.getInitParameter("jobsworth.error.email_sender_address"),
  :exception_recipients => $servlet_context.getInitParameter("jobsworth.error.exception_recipients")