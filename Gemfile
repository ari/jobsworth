source 'http://rubygems.org'

gem "rails", "3.2.22"
gem "jruby-jars", "9.0.4.0"

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

  # https://github.com/rails/rails/blob/3-2-stable/activerecord/lib/active_record/connection_adapters/mysql2_adapter.rb#L3
  gem 'mysql2', '~> 0.3.10', group: :mysql
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
  gem "faker", '0.3.1'
  gem "spork"
  gem "rdoc"
  gem 'ci_reporter_rspec'
  gem 'ci_reporter_cucumber'
  gem 'ci_reporter_test_unit'
  gem 'ci_reporter_minitest'

  gem "codeclimate-test-reporter", :require => false
end

group :development do
  gem 'annotate'
end

group :test, :cucumber do
  gem 'rspec-rails', '~> 2.0'
  gem 'capybara'
  gem 'poltergeist'
  gem 'factory_girl_rails'
  gem "machinist", '1.0.6'
  gem "shoulda", :require => false
  gem 'database_cleaner', '1.2.0'
  gem "launchy"
  gem 'timecop'
  # https://github.com/thoughtbot/paperclip/issues/1445#issuecomment-44084655
  gem 'test_after_commit'
end

group :cucumber do
  gem 'cucumber-rails'
  gem 'crb'
end
