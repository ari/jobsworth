# Be sure to restart your web server when you modify this file.

# Uncomment below to force Rails into production mode when
# you don't control web/app server and can't set it the proper way
# ENV['RAILS_ENV'] ||= 'production'

# RAILS_GEM_VERSION="2.3.2"

# Bootstrap the Rails environment, frameworks, and default configuration
require File.join(File.dirname(__FILE__), 'boot')

Rails::Initializer.run do |config|
  # Settings in config/environments/* take precedence those specified here

  # Skip frameworks you're not going to use
  # config.frameworks -= [ :action_web_service, :action_mailer ]

  # Add additional load paths for your own custom dirs
  # config.load_paths += %W( #{RAILS_ROOT}/extras )

  # Force all environments to use the same logger level
  # (by default production uses :info, the others :debug)
  # config.log_level = :debug

  # Use the database for sessions instead of the file system
  # (create the session table with 'rake create_sessions_table')
  config.action_controller.session_store = :active_record_store

  # Enable page/fragment caching by setting a file-based store
  # (remember to create the caching directory and make it readable to the application)
  config.action_controller.cache_store = :file_store, "#{RAILS_ROOT}/tmp/cache"

  # Activate observers that should always be running
  # config.active_record.observers = :cacher, :garbage_collector

  # Make Active Record use UTC-base instead of local time
  config.active_record.default_timezone = :utc

  # Use Active Record's schema dumper instead of SQL when creating the test database
  # (enables use of different database adapters for development and test environments)
  # config.active_record.schema_format = :ruby

  # See Rails::Configuration for more options
  config.logger = Logger.new("#{RAILS_ROOT}/log/#{ENV['RAILS_ENV']}.log", 5)
  
  config.gem 'splattael-activerecord_base_without_table',	:lib    => 'activerecord_base_without_table',
															:source => 'http://gems.github.com'

  #config.gem 'rails', :version => '2.3.2'
  #config.gem 'actionpack', :version => '2.3.2'
  #config.gem 'actionmailer', :version => '2.3.2'
  #config.gem 'activerecord', :version => '2.3.2'
  #config.gem 'activeresource', :version => '2.3.2'
  #config.gem 'activesupport', :version => '2.3.2'
          
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
  config.gem 'hoe', :version => '1.12.1'
  config.gem 'gchartrb', :version => '0.8', :lib => 'google_chart'
  config.gem 'test-spec', :version => '0.10.0', :lib => 'test/spec'
  config.gem 'echoe', :version => '3.1.1'
  
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

require File.join(File.dirname(__FILE__), '../lib/rails_extensions')
require_dependency 'tzinfo'
include TZInfo

require File.join(File.dirname(__FILE__), '../lib/misc.rb')


ActiveRecord::Base.verification_timeout = 14400

load "environment.local.rb" if File.exists?("environment.local.rb")

Localization.load

