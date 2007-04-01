$:.unshift(File.dirname(__FILE__) + '/../lib')

require 'rubygems'
require 'test/unit'
require 'action_controller'
require "#{File.dirname(__FILE__)}/../init"

ActionController::Base.logger = Logger.new(File.dirname(__FILE__) + "/debug.log")
ActionController::Base.logger.level = Logger::DEBUG

require "#{File.dirname(__FILE__)}/test_controller"

class Test::Unit::TestCase #:nodoc:
end
