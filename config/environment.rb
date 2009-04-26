# Be sure to restart your web server when you modify this file.

# Uncomment below to force Rails into production mode when
# you don't control web/app server and can't set it the proper way
# ENV['RAILS_ENV'] ||= 'production'

# Specifies gem version of Rails to use when vendor/rails is not present
RAILS_GEM_VERSION = '2.3.2' unless defined? RAILS_GEM_VERSION


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

  # See Rails::Configuration for more options
  config.logger = Logger.new("#{RAILS_ROOT}/log/#{ENV['RAILS_ENV']}.log", 5)
  
  config.gem 'splattael-activerecord_base_without_table',	:lib    => 'activerecord_base_without_table',
															:source => 'http://gems.github.com'

  config.gem 'rails', :version => '2.3.2'
  config.gem 'actionpack', :version => '2.3.2'
  config.gem 'actionmailer', :version => '2.3.2'
  config.gem 'activerecord', :version => '2.3.2'
  config.gem 'activeresource', :version => '2.3.2'
  config.gem 'activesupport', :version => '2.3.2'
          
  config.gem 'mysql', :version => '2.7'
  config.gem 'daemons', :version => '1.0.10'
  config.gem 'eventmachine', :version => '0.12.6'
  config.gem 'json', :version => '1.1.4'
  config.gem 'mislav-will_paginate', :version => '2.3.8', :lib => 'will_paginate', :source => 'http://gems.github.com'
  config.gem 'ferret', :version => '0.11.6'
  config.gem 'acts_as_ferret', :version => '0.4.3'
  config.gem 'fastercsv', :version => '1.4.0'
  config.gem 'icalendar', :version => '1.1.0'
  config.gem 'tzinfo', :version => '0.3.12'
  config.gem 'RedCloth', :version => '4.1.9'
  config.gem 'rmagick', :version => '2.9.1'
  config.gem 'ZenTest', :version => '4.0.0'
  #config.gem 'hoe', :version => '1.12.1'
  config.gem 'gchartrb', :version => '0.8', :lib => 'google_chart'
  config.gem 'test-spec', :version => '0.10.0', :lib => 'test/spec'
  #config.gem 'echoe', :version => '3.1.1'
  
  # Juggernaut is installed as a plugin and heavily customised, therefore it cannot be listed here.
  
  # Required for development only
  config.gem 'allison', :version => '2.0.3'
  config.gem 'markaby', :version => '0.5'
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

ActiveRecord::Base.verification_timeout = 14400
require File.join(File.dirname(__FILE__), '../lib/rails_extensions')

load File.join(File.dirname(__FILE__), 'environment.local.rb')
require File.join(File.dirname(__FILE__), '../lib/misc.rb')

require_dependency 'tzinfo'
include TZInfo