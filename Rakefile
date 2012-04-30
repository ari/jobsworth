# Add your own tasks in files placed in lib/tasks ending in .rake,
# for example lib/tasks/capistrano.rake, and they will automatically be available to Rake.

require File.expand_path('../config/application', __FILE__)

require 'rake'
require 'rake/testtask'
require 'rdoc/task'

require 'rubygems'

if Rails.env == "test"
  require 'ci/reporter/rake/rspec'
  require 'ci/reporter/rake/cucumber'
  require 'ci/reporter/rake/test_unit'
  require 'ci/reporter/rake/minitest'
end

Jobsworth::Application.load_tasks
