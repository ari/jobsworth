source 'https://rubygems.org'

gem 'rails', '~> 4.2'

gem 'will_paginate'
gem 'icalendar'
gem 'tzinfo'
gem 'gchartrb', :require => 'google_chart'
gem 'paperclip'
gem 'json'
gem 'acts_as_list'
gem 'dynamic_form'
gem 'remotipart'
gem 'exception_notification'
gem 'net-ldap'
gem 'devise', '~> 3'
gem 'devise-encryptable'
gem 'jquery-rails'
gem 'jquery-ui-rails'
gem 'delayed_job_active_record'
gem 'cocaine'
gem 'hashie'
gem 'rufus-scheduler'
gem 'localeapp', :require => false
gem 'human_attribute'
gem 'rails-observers'
gem 'lograge'
gem 'logstash-event'

# The following gem is needed on MRI, but also for testing on jruby (since we use the servlet store only in production)
gem 'activerecord-session_store'

platforms :jruby do
  gem 'jruby-rack-worker', :require => false
  gem 'warbler', :require => false
  gem 'activerecord-jdbc-adapter'
  gem 'activerecord-jdbcmysql-adapter', group: :mysql
  gem 'activerecord-jdbcpostgresql-adapter', group: :postgres
  gem 'activerecord-jdbcsqlite3-adapter', group: :sqlite
end

platforms :mri do
  gem 'daemons'
  gem 'gherkin'
  gem 'mysql2',   group: :mysql
  gem 'pg',       group: :postgres
  gem 'sqlite3',  group: :sqlite

  gem 'ruby-prof', group: :test
end

# Gems used only for assets and not required
# in production environments by default.
group :assets do
  gem 'sass-rails'
  gem 'bootstrap-sass', '<3'
  gem 'closure-compiler'
end

group :debug do
  gem 'byebug', platform: :mri
end

group :test do
  gem 'faker', '0.3.1'
  gem 'spork'
  gem 'ci_reporter_rspec'
  gem 'ci_reporter_cucumber'
  gem 'ci_reporter_test_unit'
  gem 'ci_reporter_minitest'

  gem 'codacy-coverage', :require => false
end

group :development do
  gem 'quiet_assets'
  gem 'annotate'
  gem 'rdoc'
  gem "bullet"
end

group :test, :development do
  gem 'rails-perftest', platform: :mri
  gem 'pry'
end

group :test, :cucumber do
  gem 'rspec-rails'
  gem 'capybara', '2.7'
  gem 'poltergeist'
  gem 'factory_girl_rails'
  gem 'machinist', '1.0.6'
  gem 'shoulda', :require => false
  gem 'database_cleaner', '1.2.0'
  gem 'launchy'
  gem 'timecop'
  # https://github.com/thoughtbot/paperclip/issues/1445#issuecomment-44084655
  gem 'test_after_commit'
  gem 'rspec-activemodel-mocks'
end

group :cucumber do
  gem 'cucumber-rails'
  gem 'crb'
end
