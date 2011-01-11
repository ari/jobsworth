class EmailDelivery < ActiveRecord::Base
  belongs_to :work_log
  belongs_to :email_address
  
  
  # this method will send all undelivered work log notifications
  # it should be called regularly in production environment
  def EmailDelivery.cron
    EmailDelivery.select(:status=>'queued').includes(:work_log).each{|delivery|
    	if delivery.work_log.log_type == EventLog::TASK_CREATED
				Notifications.created(delivery)
			else
				Notifications.changed(delivery)
			end
    	delivery.status = 'sent'
      delivery.save!
    }
  end
  
  
end

# == Schema Information
#
# Table name: email_deliveries
#
#  id               :integer(4)      not null, primary key
#  work_log_id      :integer(4)
#  email_address_id :integer(4)
#  status           :string(255)
#  created_at       :datetime
#  updated_at       :datetime
#

