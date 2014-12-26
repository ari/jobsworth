# Add your own tasks in files placed in lib/tasks ending in .rake,
# for example lib/tasks/capistrano.rake, and they will automatically be available to Rake.

require File.expand_path('../config/application', __FILE__)

if Rails.env.test? && ENV['CI']
  require 'ci/reporter/rake/rspec'
  require 'ci/reporter/rake/cucumber'
  require 'ci/reporter/rake/test_unit'
  require 'ci/reporter/rake/minitest'

  task :rspec => 'ci:setup:rspec'
  task :cucumber => 'ci:setup:cucumber'
  task :minitest => 'ci:setup:minitest'
  task :testunit => 'ci:setup:testunit'
end

require 'ci/travis'

if Rails.env.test?
  require 'coveralls/rake/task'
  Coveralls::RakeTask.new
  task :test_with_coveralls => [:spec, :features, 'coveralls:push']
end

Jobsworth::Application.load_tasks
