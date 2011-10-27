Jobsworth::Application.configure do
  # Settings specified here will take precedence over those in config/environment.rb

  # In the development environment your application's code is reloaded on
  # every request.  This slows down response time but is perfect for development
  # since you don't have to restart the webserver when you make code changes.
  config.cache_classes = false

  # Log error messages when you accidentally call methods on nil.
  config.whiny_nils = true

  # Show full error reports and disable caching
  config.consider_all_requests_local       = true
  config.action_controller.perform_caching = false

  # Don't care if the mailer can't send
  config.action_mailer.raise_delivery_errors = false
  config.action_mailer.default_url_options = { :host => 'localhost:3000' }
  #Change this to your real configuration
  config.action_mailer.smtp_settings = {
    :address        => 'smtp.gmail.com',
    :port           => 587,
    :domain         => 'gmail.com',
    :authentication => :login,
    :user_name      => 'username@host.com', #ex. intale.a@gmail.com
    :password       => 'password'
  }

  # Print deprecation notices to the Rails logger
  config.active_support.deprecation = :log

  config.after_initialize do
#    Bullet.enable = true
#    Bullet.alert = false
#    Bullet.bullet_logger= true
#    Bullet.console = false
#    Bullet.rails_logger = false
#    Bullet.growl = false
#    Bullet.disable_browser_cache= false
  end

  # Do not compress assets
  config.assets.compress = false

  # Expands the lines which load the assets
  config.assets.debug = true
end
