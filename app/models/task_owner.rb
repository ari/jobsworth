# A user who is assigned to a task 
class TaskOwner < ActiveRecord::Base
  belongs_to :user
  belongs_to :task

  named_scope :unread, :conditions => { :unread => true }
end
