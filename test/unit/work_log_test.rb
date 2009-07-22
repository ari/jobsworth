require File.dirname(__FILE__) + '/../test_helper'

class WorkLogTest < ActiveRecord::TestCase
  fixtures :work_logs, :customers, :companies

  def setup
    @work_log = WorkLog.find(1)
    @work_log.company = companies(:cit)
    @work_log.customer = @work_log.company.customers.first
  end

  should "set customer_id from customer_name=" do
    c = @work_log.company.customers.last
#    c = Customer.all.last
    assert_not_equal c, @work_log.customer
    
    @work_log.customer_name = c.name
    assert_equal c, @work_log.customer
  end
  
  should "return the customer name" do
    assert_equal @work_log.customer.name, @work_log.customer_name
  end 
end
