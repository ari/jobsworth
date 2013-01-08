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

platforms :jruby do
  gem 'activerecord-jdbc-adapter'
  gem 'activerecord-jdbcmysql-adapter'
  gem 'warbler'
  gem 'quartz_rails', :git => "https://github.com/liufengyun/quartz_rails.git", :require => false
  gem 'jruby-rack-worker', :require => false
end

platforms :ruby do
  gem 'mysql2'
  gem "rufus-scheduler"
  gem 'daemons'
end

platforms :mri do
  group :test do
    gem 'ruby-prof'
  end
end
  
# Gems used only for assets and not required
# in production environments by default.
group :assets do
  gem 'sass-rails'
  gem 'bootstrap-sass'
end

group :test, :development do
  gem "machinist",        '1.0.6'
end

group :test do
  gem "shoulda", :require => false
  gem "rspec-rails"
  gem "faker",            '0.3.1'
  gem "database_cleaner"
  gem "capybara"
  gem "launchy"
  gem "simplecov", :require => false
  gem "spork"
  gem "rdoc"
  gem "ci_reporter"
end

group :development do
  gem "annotate"
end
