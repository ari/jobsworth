# A user who is assigned to a task 
class TaskOwner < ActiveRecord::Base
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
# Table name: task_owners
#
#  id                   :integer(4)      not null, primary key
#  user_id              :integer(4)
#  task_id              :integer(4)
#  unread               :boolean(1)      default(FALSE)
#  notified_last_change :boolean(1)      default(TRUE)
#
# Indexes
#
#  task_owners_user_id_index  (user_id)
#  task_owners_task_id_index  (task_id)
#

