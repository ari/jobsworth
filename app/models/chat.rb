# This model represents an instant message session between two users
#
# One instance is created for each side of the conversation, to track
# individual counts and statuses

class Chat < ActiveRecord::Base
  belongs_to :user
  belongs_to :target, :class_name => 'User'
  has_many   :chat_messages, :order => 'chat_messages.id desc', :limit => 20, :conditions => [ "archived = ?", false ]
  has_many   :archived_messages, :order => 'chat_messages.id desc', :conditions => [ "archived = ?", true ], :dependent => :destroy, :class_name => 'ChatMessage'
  has_many   :all_messages, :order => 'chat_messages.id desc', :dependent => :destroy, :class_name => 'ChatMessage'

  acts_as_list :scope => 'user_id = #{user_id}'
  
  def unread
    ChatMessage.count(:conditions => ["chat_id = ? AND chat_messages.id > ? AND archived = ?", self.id, self.last_seen.to_i, false])
  end
end

# == Schema Information
#
# Table name: chats
#
#  id         :integer(4)      not null, primary key
#  user_id    :integer(4)
#  target_id  :integer(4)
#  active     :integer(4)      default(1)
#  position   :integer(4)      default(0)
#  last_seen  :integer(4)      default(0)
#  created_at :datetime
#  updated_at :datetime
#

