# Add your own tasks in files placed in lib/tasks ending in .rake,
# for example lib/tasks/capistrano.rake, and they will automatically be available to Rake.

require File.expand_path('../config/application', __FILE__)

require 'rake'
require 'rake/testtask'
require 'rdoc/task'

begin
  require 'ci/reporter/rake/rspec'
  require 'ci/reporter/rake/test_unit'
  require 'ci/reporter/rake/cucumber'
rescue LoadError
  # no worry... only needed in testing
end

Jobsworth::Application.load_tasks
