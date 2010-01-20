require 'test_helper'

class TaskCustomerTest < ActiveSupport::TestCase 
  should_belong_to :task
  should_belong_to :customer
end

# == Schema Information
#
# Table name: task_customers
#
#  id          :integer(4)      not null, primary key
#  customer_id :integer(4)
#  task_id     :integer(4)
#  created_at  :datetime
#  updated_at  :datetime
#

