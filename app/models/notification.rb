# Notify these users on task changes

class Notification < ActiveRecord::Base
  belongs_to :user
  belongs_to :task

  named_scope :unread, :conditions => { :unread => true }
end
