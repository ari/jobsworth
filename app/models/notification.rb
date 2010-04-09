# Notify these users on task changes

class Notification < ActiveRecord::Base
  belongs_to :user
  belongs_to :task#, :touch => true

  named_scope :unread, :conditions => { :unread => true }

  # touch currently calls validations, which fail when creating from email, so update manually
  # see https://rails.lighthouseapp.com/projects/8994/tickets/2520-patch-activerecordtouch-without-validations
  after_save :touch_task

  private

  def touch_task
    self.task.update_attributes(:updated_at => Time.now) if self.task
  end

end


# == Schema Information
#
# Table name: notifications
#
#  id                   :integer(4)      not null, primary key
#  task_id              :integer(4)
#  user_id              :integer(4)
#  unread               :boolean(1)      default(FALSE)
#  notified_last_change :boolean(1)      default(TRUE)
#
# Indexes
#
#  index_notifications_on_user_id  (user_id)
#  index_notifications_on_task_id  (task_id)
#

