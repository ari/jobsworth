require "test_helper"

class WorkLogTest < ActiveRecord::TestCase
  fixtures :work_logs, :customers, :companies, :email_addresses

  should validate_presence_of(:started_at)

  def setup
    @work_log = WorkLog.first
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

  should "return new User object if work log doesn't have user" do
    log = WorkLog.create!(:company => companies(:cit),
                          :body => "Test worklog",
                          :started_at => Time.now,
                          :email_address => email_addresses(:unknown_user_email))

    user = log.user
    assert user.new_record?
    assert_equal 'Unknown User (unknownuser@jobsworth.com)', user.name
    assert_equal log.email_address.email, user.email
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
#  user_id          :integer(4)      default(0)
#  task_id          :integer(4)
#  project_id       :integer(4)      default(0), not null
#  company_id       :integer(4)      default(0), not null
#  customer_id      :integer(4)      default(0), not null
#  started_at       :datetime        not null
#  duration         :integer(4)      default(0), not null
#  body             :text
#  log_type         :integer(4)      default(0)
#  paused_duration  :integer(4)      default(0)
#  comment          :boolean(1)      default(FALSE)
#  exported         :datetime
#  status           :integer(4)      default(0)
#  access_level_id  :integer(4)      default(1)
#  email_address_id :integer(4)
#
# Indexes
#
#  work_logs_company_id_index                 (company_id)
#  work_logs_customer_id_index                (customer_id)
#  work_logs_project_id_index                 (project_id)
#  work_logs_task_id_index                    (task_id,log_type)
#  index_work_logs_on_task_id_and_started_at  (task_id,started_at)
#  work_logs_user_id_index                    (user_id,task_id)
#

