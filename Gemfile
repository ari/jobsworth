source 'http://rubygems.org'

gem "rails", "3.2.21"
gem "jruby-jars", "1.7.17"

gem "will_paginate"
gem 'icalendar'
gem 'tzinfo'
gem 'RedCloth', :require=>'redcloth'
gem 'gchartrb', :require=>"google_chart"
gem 'paperclip', '<4'
gem 'json'
gem 'acts_as_tree', '1.5'
gem 'acts_as_list'
gem 'dynamic_form'
gem 'remotipart'
gem "exception_notification"
gem 'net-ldap'
gem 'devise', '<3.0'
gem 'devise-encryptable'
gem 'jquery-rails', '~> 2.3.0'
gem 'closure-compiler'
gem 'delayed_job_active_record'
gem 'cocaine'
gem 'hashie'
gem 'rufus-scheduler'
gem 'localeapp', :require => false
gem 'human_attribute'

platforms :jruby do
  gem 'jruby-rack-worker', :require => false
  gem 'warbler', :require => false
  gem 'activerecord-jdbcmysql-adapter', '> 1.3', group: :mysql
  gem 'activerecord-jdbcpostgresql-adapter', '> 1.3', group: :postgres
  gem 'activerecord-jdbcsqlite3-adapter', '> 1.3', group: :sqlite
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
  gem 'bootstrap-sass', '~> 2.3.2.2'
end

group :debug do
  gem 'debugger', platform: :mri
end

group :test do
  gem "rspec"
  gem "faker",            '0.3.1'
  gem "simplecov", :require => false
  gem 'coveralls', :require => false
  gem "spork"
  gem "rdoc"
  gem 'ci_reporter_rspec'
  gem 'ci_reporter_cucumber'
  gem 'ci_reporter_test_unit'
  gem 'ci_reporter_minitest'
end

group :development do
  gem 'annotate'
end

group :test, :cucumber do
  gem 'capybara'
  gem 'poltergeist'
  gem 'factory_girl_rails'
  gem "machinist",        '1.0.6'
  gem 'rspec-rails'
  gem "shoulda", :require => false
  gem 'database_cleaner', '1.2.0'
  gem "launchy"
  gem 'timecop'
end

group :cucumber do
  gem 'cucumber-rails'
  gem 'crb'
end

