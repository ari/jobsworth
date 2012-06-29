require "test_helper"

class WorkLogTest < ActiveRecord::TestCase
  should validate_presence_of(:started_at)

  def setup
    @work_log = WorkLog.make
  end
  subject { @work_log }

  should "set customer_id from customer_name=" do
    c = Customer.make(:company => @work_log.company)
    assert_not_equal c, @work_log.customer

    @work_log.customer_name = c.name
    assert_equal c, @work_log.customer
  end

  should "return the customer name" do
    assert_equal @work_log.customer.name, @work_log.customer_name
  end

  should "return new User object if work log doesn't have user" do
    ed = EmailAddress.make
    log = WorkLog.make(
      :started_at => Time.now,
      :email_address => ed,
      :user => nil,
      :task => Task.make
    )

    user = log.user
    assert user.new_record?
    assert_equal "Unknown User (#{ed.email})", user.name
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

      log = WorkLog.make_unsaved(:company => @attr.company, :duration => 100)
      assert !log.valid?
    end
  end

  context "mark task as unread for user" do
    setup do
      @company = Company.make
      2.times{ User.make(:access_level_id => 1, :company => @company) }
      2.times{ User.make(:access_level_id => 2, :company => @company) }
      @company.reload
      @task = Task.make(:company => @company, :users => @company.users)
      @task.task_users.update_all("unread=false")
    end

    should "mark as unread task for users, except WorkLog#user" do
      @work_log = WorkLog.make(:task => @task, :body =>"some text", :company => @company, :user => @company.users.first)
      assert_equal @task.task_users.find_all_by_unread(true).size, 3
      assert_nil @task.task_users.find_all_by_unread(true).detect { |tu| tu.user_id == @company.users.first.id }
      assert_equal @task.task_users.find_all_by_unread(true), @task.task_users.find(:all, :conditions => ["task_users.user_id != ?", @work_log.user_id])
    end

    should "mark as uread task for users with access to work log" do
      @work_log = WorkLog.make(:task => @task, :body => "some text", :company => @company, :user => @company.users.first, :access_level_id => 2)
      assert_equal @task.task_users.find_all_by_unread(true).size, 2
      assert_equal @task.task_users.find_all_by_unread(true), @task.task_users.find(:all, :include => :user,
                                                                                :conditions => ["users.access_level_id =? and task_users.user_id != ? ", 2, @work_log.user_id ])
    end
  end

  context "task notify" do
    setup do
      @company = Company.make
      2.times{ User.make(:access_level_id => 1, :company => @company) }
      2.times{ User.make(:access_level_id => 2, :company => @company) }
      @company.reload

      @task = Task.make(:company => @company, :users => @company.users)
    end

    should "bad data in task_users & email_addresses to send email correctly" do
      ActionMailer::Base.deliveries = []

      @user = User.make(:company => @company, :email => "unknown@domain2.com")

      ea1 = EmailAddress.new(:email => "unknown@domain2.com")
      ea1.save!(:validate => false)

      @task.email_addresses << ea1
      @task.users << @user

      worklog = WorkLog.make(
        :company => @task.company,
        :project => @task.project,
        :user => @user,
        :task => @task,
        :body => "test content"
      )
      worklog.notify

      assert worklog.email_deliveries.detect {|ed| ed.user == @user and ed.email == @user.email }
      assert_nil worklog.email_deliveries.detect {|ed| !ed.user and ed.email == ea1.email }

      assert_equal ActionMailer::Base.deliveries.size, 5
    end

    should "send email correctly if current user donesn't receive own notification" do
      ActionMailer::Base.deliveries = []

      @user = User.make(:company => @company, :email => "unknown@domain2.com", :receive_own_notifications => false)
      @task.users << @user

      worklog = WorkLog.make(
        :company => @task.company,
        :project => @task.project,
        :user => @user,
        :task => @task,
        :body => "test content"
      )
      worklog.notify

      assert_equal ActionMailer::Base.deliveries.size, 4
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
#  paused_duration  :integer(4)      default(0)
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

