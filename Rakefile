# Add your own tasks in files placed in lib/tasks ending in .rake,
# for example lib/tasks/capistrano.rake, and they will automatically be available to Rake.

require File.expand_path('../config/application', __FILE__)

require 'rake'
require 'rake/testtask'
require 'rake/rdoctask'

begin
  require 'delayed/tasks'
rescue LoadError
  STDERR.puts "Run `bundle install` to install delayed_job"
end

require 'ci/reporter/rake/rspec'
require 'ci/reporter/rake/test_unit'
require 'ci/reporter/rake/cucumber'

Clockingit::Application.load_tasks