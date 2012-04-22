require "test_helper"

class EmailDeliveryTest < ActiveRecord::TestCase

  def setup
    ActionMailer::Base.deliveries.clear
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

