# Add your own tasks in files placed in lib/tasks ending in .rake,
# for example lib/tasks/capistrano.rake, and they will automatically be available to Rake.

require File.expand_path('../config/application', __FILE__)

if Rails.env.test? && ENV['JENKINS']
  puts "\nJenkins CI reporter gems enabled."

  require 'ci/reporter/rake/rspec'
  task :rspec => 'ci:setup:rspec'

  require 'ci/reporter/rake/cucumber'
  require 'ci/reporter/rake/test_unit'
  require 'ci/reporter/rake/minitest'
  task :utest => 'ci:setup:testunit'
end

require 'ci/travis'

Jobsworth::Application.load_tasks
