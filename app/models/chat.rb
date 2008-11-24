# This model represents an instant message session between two users
#
# One instance is created for each side of the conversation, to track
# individual counts and statuses

class Chat < ActiveRecord::Base
  belongs_to :user
  belongs_to :target, :class_name => 'User'
  has_many   :chat_messages, :order => 'chat_messages.id desc', :limit => 20, :conditions => "archived = 0"
  has_many   :archived_messages, :order => 'chat_messages.id desc', :conditions => "archived = 1", :dependent => :destroy, :class_name => 'ChatMessage'
  has_many   :all_messages, :order => 'chat_messages.id desc', :dependent => :destroy, :class_name => 'ChatMessage'

  acts_as_list :scope => 'user_id = #{user_id}'
  
  def unread
    ChatMessage.count(:conditions => ["chat_id = ? AND chat_messages.id > ? AND archived = 0", self.id, self.last_seen.to_i])
  end
end
