require "test_helper"

class EmailDeliveryTest < ActiveRecord::TestCase

  def setup
    ActionMailer::Base.deliveries.clear
  end
  
  should "deliver notifications using EmailDelivery#cron" do 
    assert_equal 5, EmailDelivery.where(:status => "queued").count
    EmailDelivery.cron
    assert_emails 5
    assert_equal 0, EmailDelivery.where(:status => "queued").count
  end
  
end
