gem "rails", "3.1.5"

source 'http://rubygems.org'
gem 'daemons'
gem "will_paginate"
gem 'icalendar'
gem 'tzinfo'
gem 'RedCloth', :require=>'redcloth'
gem 'gchartrb', :require=>"google_chart"
gem 'paperclip'
gem 'json'
gem 'acts_as_tree'
gem 'acts_as_list'
gem 'dynamic_form'
gem 'remotipart'
gem "exception_notification_rails3", :require => "exception_notifier"
gem "rufus-scheduler"
gem 'net-ldap'
gem 'devise'
gem 'devise-encryptable'
gem 'jquery-rails'
gem 'closure-compiler'

platforms :jruby do
  gem 'activerecord-jdbcmysql-adapter'
  # This is needed by now to let tests work on JRuby
  # TODO: When the JRuby guys merge jruby-openssl in
  # jruby this will be removed
  gem 'jruby-openssl'
end

platforms :ruby do
  gem 'mysql2'
end

platforms :mri do
  group :test do
    gem 'ruby-prof'
  end
end
  
# Gems used only for assets and not required
# in production environments by default.
group :assets do
  gem 'sass-rails', '3.1.5'   # https://github.com/rails/sass-rails/issues/100
  gem 'bootstrap-sass'
end

group :test, :development do
  gem "machinist",        '1.0.6'
end

group :test do
  gem "shoulda"
  gem "rspec-rails"
  gem "mocha"
  gem "faker",            '0.3.1'
  gem "cucumber"
  gem "database_cleaner"
  gem "cucumber-rails"
  gem "capybara"
  gem "launchy"
  gem "simplecov", :require => false
  gem "spork"
  gem "rdoc"
  gem "minitest"
  gem "turn"
  gem "ci_reporter"
end

group :development do
  gem "annotate"
end
