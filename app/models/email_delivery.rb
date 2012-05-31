class EmailDelivery < ActiveRecord::Base
  belongs_to :work_log
  belongs_to :user

  validates_presence_of :work_log, :email # email is the recipient's address

  # this method will send all undelivered work log notifications
  # it should be called regularly in production environment
  # TODO should it be extracted into a lib ?
  def EmailDelivery.cron
    deliveries = EmailDelivery.where(:status=>'queued').includes(:work_log)
    logger.info "EmailDelivery.cron: trying to deliver #{deliveries.size} records"
    deliveries.each{|delivery|
      logger.info "EmailDelivery.cron: trying to send work log: #{delivery.work_log.inspect}"
      delivery.deliver
    }
  end

  def username_or_email
    user ? user.name : self.email
  end

  def deliver
    work_log = self.work_log
    if work_log.event_log.event_type == EventLog::TASK_CREATED
      Notifications.created(self).deliver
    else
      Notifications.changed(self).deliver
    end
    self.status = 'sent'
    self.save!
  rescue Exception => exc
    self.status = 'failed'
    self.save(:validate => false) rescue "" # ensure no exception is raised
    logger.error "Failed to send notification delivery##{self.id}. Error : #{exc}"
    logger.error exc.backtrace
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

