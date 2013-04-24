class EmailDelivery < ActiveRecord::Base
  belongs_to :work_log
  belongs_to :user

  after_save :deliver_if_queued

  validates_presence_of :work_log, :email # email is the recipient's address

  def username_or_email
    user.try(:name) || email
  end

  def deliver
    case work_log.event_log.event_type
    when EventLog::TASK_CREATED
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

private
  def deliver_if_queued
    self.delay.deliver if status == "queued"
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

