require "test_helper"

class EmailDeliveryTest < ActiveRecord::TestCase

  def setup
    ActionMailer::Base.deliveries.clear

    @company = Company.make
    @user = User.make(:company => @company)
    @project = Project.make(:company => @company)
    3.times do
      task = TaskRecord.make(:company => @company, :project => @project)
      work_log = WorkLog.make(:task => task, :user => @user, :company => @company, :project => @project)

      work_log.create_event_log(
        :company     => work_log.company,
        :project     => work_log.project,
        :user        => work_log.user,
        :event_type  => rand(100) % 2 == 0 ? EventLog::TASK_CREATED : EventLog::TASK_COMPLETED,
        :body        => Faker::Lorem.paragraph
      )
    end
  end

  should "not validate when WorkLog is missing" do
    assert_raises ActiveRecord::RecordInvalid do
      EmailDelivery.make(work_log: nil)
    end
  end

  should "not validate when Email is missing" do
    assert_raises ActiveRecord::RecordInvalid do
      EmailDelivery.make(email: nil)
    end
  end

  should "test invalid record in email delivery" do
    ActionMailer::Base.deliveries.clear
    EmailDelivery.delete_all

    task = TaskRecord.make(:company => @company, :project => @project)
    wl1 = WorkLog.make(:task => task, :user => @user, :company => @company, :project => @project)
    wl2 = WorkLog.make(:task => task, :user => @user, :company => @company, :project => @project)
    EmailDelivery.new(:status => "queued", :email => nil).save(:validate => false)
    EmailDelivery.make(:status => "queued", :email => "test1@example.com", :work_log => wl1)
    EmailDelivery.new(:status => "queued", :email => "abc@example.com").save(:validate => false)
    EmailDelivery.make(:status => "queued", :email => "test2@example.com", :work_log => wl2)
    EmailDelivery.make(:status => "sent", :email => "test3@example.com")

    assert_emails 2
    assert_equal 2, EmailDelivery.where(:status => "failed").count
    assert_equal 3, EmailDelivery.where(:status => "sent").count
  end
end


# == Schema Information
#
# Table name: email_deliveries
#
#  id          :integer(4)      not null, primary key
#  work_log_id :integer(4)
#  status      :string(255)
#  created_at  :datetime
#  updated_at  :datetime
#  email       :string(255)
#  user_id     :integer(4)
#
# Indexes
#
#  index_email_deliveries_on_status  (status)
#

