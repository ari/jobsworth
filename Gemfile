source 'http://rubygems.org'

gem "rails", "3.2.10"

gem "will_paginate"
gem 'icalendar'
gem 'tzinfo'
gem 'RedCloth', :require=>'redcloth'
gem 'gchartrb', :require=>"google_chart"
gem 'paperclip', '>3.1'
gem 'json'
gem 'acts_as_tree'
gem 'acts_as_list'
gem 'dynamic_form'
gem 'remotipart'
gem "exception_notification_rails3", :require => "exception_notifier"
gem 'net-ldap'
gem 'devise'
gem 'devise-encryptable'
gem 'jquery-rails'
gem 'closure-compiler'
gem 'delayed_job_active_record'
gem 'cocaine'
gem 'hashie'
gem 'rufus-scheduler'

platforms :jruby do
  gem 'warbler'
  gem 'jruby-rack-worker', :require => false

  gem 'activerecord-jdbcmysql-adapter',      group: :mysql
  gem 'activerecord-jdbcpostgresql-adapter', group: :postgres
  gem 'activerecord-jdbcsqlite3-adapter',    group: :sqlite
end

platforms :mri do
  gem 'daemons'

  gem 'mysql2',  group: :mysql
  gem 'pg',      group: :postgres
  gem 'sqlite3', group: :sqlite

  gem 'ruby-prof', group: :test
end

# Gems used only for assets and not required
# in production environments by default.
group :assets do
  gem 'sass-rails'
  gem 'bootstrap-sass'
end

group :test, :development do
  gem 'debugger', platform: :mri
  gem "machinist",        '1.0.6'
  #gem 'factory_girl_rails'
end

group :test do
  gem "rspec"
  gem "faker",            '0.3.1'
  gem "simplecov", :require => false
  gem "spork"
  gem "rdoc"
  gem 'ci_reporter'
end

group :development do
  gem "annotate"
end

group :test, :cucumber do
  gem 'capybara'
  gem 'poltergeist'
  gem 'factory_girl_rails'
  gem 'rspec-rails'
  gem "shoulda", :require => false
  gem 'database_cleaner'
  gem "launchy"
end

group :cucumber do
  gem 'cucumber-rails'
  gem 'crb'
end
