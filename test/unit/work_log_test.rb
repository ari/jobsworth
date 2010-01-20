require File.dirname(__FILE__) + '/../test_helper'

class WorkLogTest < ActiveRecord::TestCase
  fixtures :work_logs, :customers, :companies

  should_validate_presence_of :started_at

  def setup
    @work_log = WorkLog.find(1)
    @work_log.company = companies(:cit)
    @work_log.customer = @work_log.company.customers.first
  end
  subject { @work_log }

  should "set customer_id from customer_name=" do
    c = @work_log.company.customers.last
    assert_not_equal c, @work_log.customer
    
    @work_log.customer_name = c.name
    assert_equal c, @work_log.customer
  end
  
  should "return the customer name" do
    assert_equal @work_log.customer.name, @work_log.customer_name
  end 

  context "a mandatory custom attribute on work logs" do
    setup do
      @attr = CustomAttribute.create!(:attributable_type => "WorkLog",
                                      :display_name => "test",
                                      :company => @work_log.company,
                                      :mandatory => 1)
    end

    should "only validate custom attribute for work added type" do
      log = WorkLog.make_unsaved(:company => @attr.company)
      assert log.valid?

      log = WorkLog.make_unsaved(:company => @attr.company, 
                                 :log_type => EventLog::TASK_WORK_ADDED)
      assert !log.valid?
    end
  end
end

# == Schema Information
#
# Table name: work_logs
#
#  id               :integer(4)      not null, primary key
#  user_id          :integer(4)      default(0), not null
#  task_id          :integer(4)
#  project_id       :integer(4)      default(0), not null
#  company_id       :integer(4)      default(0), not null
#  customer_id      :integer(4)      default(0), not null
#  started_at       :datetime        not null
#  duration         :integer(4)      default(0), not null
#  body             :text
#  log_type         :integer(4)      default(0)
#  scm_changeset_id :integer(4)
#  paused_duration  :integer(4)      default(0)
#  comment          :boolean(1)      default(FALSE)
#  exported         :datetime
#  approved         :boolean(1)
#

