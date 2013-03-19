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
  gem 'warbler'
  gem 'jruby-rack-worker', :require => false
  # This is needed by now to let tests work on JRuby
  # TODO: When the JRuby guys merge jruby-openssl in jruby this will be removed
  gem 'jruby-openssl'

  gem 'activerecord-jdbcmysql-adapter',      group: :mysql
  gem 'activerecord-jdbcpostgresql-adapter', group: :postgres
  gem 'activerecord-jdbcsqlite3-adapter',    group: :sqlite
end

platforms :mri do
  gem "rufus-scheduler"
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
  gem "machinist",        '1.0.6'
end

group :test do
  gem "shoulda", :require => false
  gem "rspec"
  gem "rspec-rails"
  gem "faker",            '0.3.1'
  gem "database_cleaner"
  gem "capybara"
  gem "launchy"
  gem "simplecov", :require => false
  gem "spork"
  gem "rdoc"
  gem 'ci_reporter'
end

group :development do
  gem "annotate"
end
