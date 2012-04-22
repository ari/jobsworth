# encoding: UTF-8
class TaskUser < ActiveRecord::Base
  belongs_to :user
  belongs_to :task, :class_name=>"AbstractTask" #, :touch => true

  scope :unread, where(:unread => true)

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
# Table name: task_users
#
#  id         :integer(4)      not null, primary key
#  user_id    :integer(4)
#  task_id    :integer(4)
#  type       :string(255)     default("TaskOwner")
#  unread     :boolean(1)
#  created_at :datetime
#  updated_at :datetime
#
# Indexes
#
#  index_task_users_on_task_id  (task_id)
#  index_task_users_on_user_id  (user_id)
#

