# Be sure to restart your web server when you modify this file.

# Uncomment below to force Rails into production mode when
# you don't control web/app server and can't set it the proper way
# ENV['RAILS_ENV'] ||= 'production'

# Specifies gem version of Rails to use when vendor/rails is not present
RAILS_GEM_VERSION = '2.3.3' unless defined? RAILS_GEM_VERSION


# Bootstrap the Rails environment, frameworks, and default configuration
require File.join(File.dirname(__FILE__), 'boot')

require File.join(File.dirname(__FILE__), '../lib/localization.rb')
Localization.load

Rails::Initializer.run do |config|
  # Settings in config/environments/* take precedence over those specified here.
  # Application configuration should go into files in config/initializers
  # -- all .rb files in that directory are automatically loaded.

  # Add additional load paths for your own custom dirs
  # config.load_paths += %W( #{RAILS_ROOT}/extras )

  # Only load the plugins named here, in the order given (default is alphabetical).
  # :all can be used as a placeholder for all plugins not explicitly named
  # config.plugins = [ :exception_notification, :ssl_requirement, :all ]

  # Skip frameworks you're not going to use. To use Rails without a database,
  # you must remove the Active Record framework.
  # config.frameworks -= [ :active_record, :active_resource, :action_mailer ]


  # Use the database for sessions instead of the file system
  # (create the session table with 'rake create_sessions_table')
  config.action_controller.session_store = :active_record_store

  # Enable page/fragment caching by setting a file-based store
  # (remember to create the caching directory and make it readable to the application)
  config.action_controller.cache_store = :file_store, "#{RAILS_ROOT}/tmp/cache"

  # Activate observers that should always be running
  # config.active_record.observers = :cacher, :garbage_collector

  # Set Time.zone default to the specified zone and make Active Record auto-convert to this zone.
  # Run "rake -D time" for a list of tasks for finding time zone names.
  config.time_zone = 'UTC'

  # The default locale is :en and all translations from config/locales/*.rb,yml are auto loaded.
  # config.i18n.load_path += Dir[Rails.root.join('my', 'locales', '*.{rb,yml}')]
  # config.i18n.default_locale = :de

  # Rotate logs when they reach 50Mb and keep 5 old logs
  config.logger = Logger.new(config.log_path, 5, 50*1024*1024)
  

  config.gem 'splattael-activerecord_base_without_table', :lib => 'activerecord_base_without_table', :source => 'http://gems.github.com'
  config.gem 'mysql'
  config.gem 'daemons', :version => '1.0.10'
  config.gem 'eventmachine', :version => '0.12.8'
  config.gem 'json', :version => '1.1.7'
  config.gem 'mislav-will_paginate', :version => '2.3.8', :lib => 'will_paginate', :source => 'http://gems.github.com'
  config.gem 'ferret', :version => '0.11.6'
#  config.gem 'acts_as_ferret', :version => '0.4.3'  #installed as a plugin since the gem version breaks
  config.gem 'fastercsv', :version => '1.5.0'
  config.gem 'icalendar', :version => '1.1.0'
  config.gem 'tzinfo'
  config.gem 'RedCloth', :version => '4.2.2'
  config.gem 'rmagick', :lib => 'RMagick'
  config.gem 'gchartrb', :version => '0.8', :lib => 'google_chart'

  # Gems used for automated testing
  config.gem "thoughtbot-shoulda", :lib => "shoulda", :source => "http://gems.github.com"
  config.gem "nokogiri"
  config.gem "webrat"
  config.gem "faker"
  config.gem "notahat-machinist", :lib => "machinist", :source => "http://gems.github.com"
  
  # Juggernaut is installed as a plugin and heavily customised, therefore it cannot be listed here.

  # CUSTOM GEMS
  # Any gem files which aren't needed for the system to work, but may
  # be required for your own development should be in this file:
  custom_gems_file = "#{ RAILS_ROOT }/config/custom.gems.rb"
  load custom_gems_file if File.exist?(custom_gems_file)
  load_custom_gems(config) if respond_to?(:load_custom_gems)
end

ActionController::Base.session_options[:session_expires]= Time.local(2015,"jan")
#
# Add new inflection rules using the following format
# (all these examples are active by default):
# Inflector.inflections do |inflect|
#   inflect.plural /^(ox)$/i, '\1en'
#   inflect.singular /^(ox)en/i, '\1'
#   inflect.irregular 'person', 'people'
#   inflect.uncountable %w( fish sheep )
# end

require File.join(File.dirname(__FILE__), '../lib/rails_extensions')

load File.join(File.dirname(__FILE__), 'environment.local.rb')
require File.join(File.dirname(__FILE__), '../lib/misc.rb')

require_dependency 'tzinfo'
include TZInfo
