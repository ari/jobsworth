$CONFIG = {
	:domain => "clockingit.com",
	:replyto => "admin",
	:from => "admin",
	:prefix => "[ClockingIT]",
	:productName => "ClockingIT",
	:SSL => false
}

ActionMailer::Base.smtp_settings = {
  :address  => "localhost",
  :port  => 25,
  :domain  => 'clockingit.com'
}