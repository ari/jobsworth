require 'test_helper'

class TaskCustomerTest < ActiveSupport::TestCase 
  should_belong_to :task
  should_belong_to :customer
end
