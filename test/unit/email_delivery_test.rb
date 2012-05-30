require "test_helper"

class EmailDeliveryTest < ActiveRecord::TestCase

  def setup
    ActionMailer::Base.deliveries.clear

    WorkLog.all.each_with_index do |wl, index|
      wl.create_event_log(
        :company     => wl.company,
        :project     => wl.project,
        :user        => wl.user,
        :event_type  => index % 2 == 0 ? EventLog::TASK_CREATED : EventLog::TASK_COMPLETED,
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

  should "deliver notifications using EmailDelivery#cron" do 
    assert_equal 5, EmailDelivery.where(:status => "queued").count
    EmailDelivery.cron
    assert_emails 5
    assert_equal 0, EmailDelivery.where(:status => "queued").count
  end
  
  should "test invalid record in email delivery" do 
    EmailDelivery.delete_all

    EmailDelivery.new(:status => "queued", :email => nil).save(:validate => false)
    EmailDelivery.make :status => "queued", :email => "test1@example.com", :work_log => work_logs(:first_work_log)
    EmailDelivery.new(:status => "queued", :email => "abc@example.com").save(:validate => false)
    EmailDelivery.make :status => "queued", :email => "test2@example.com", :work_log => work_logs(:another_work_log)
    EmailDelivery.make :status => "sent", :email => "test3@example.com"

    assert_equal 4, EmailDelivery.where(:status => "queued").count
    assert_equal 1, EmailDelivery.where(:status => "sent").count

    EmailDelivery.cron

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

