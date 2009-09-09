require File.dirname(__FILE__) + '/../test_helper'

class SheetTest < ActiveRecord::TestCase
  should_validate_presence_of :task
  should_validate_presence_of :project
  should_validate_presence_of :user
end
