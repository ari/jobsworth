class Chat < ActiveRecord::Base
  belongs_to :user
  belongs_to :target, :class_name => 'User'
  has_many   :chat_messages, :order => 'id desc', :limit => 20, :dependent => :destroy, :conditions => "archived = 0"
  has_many   :archived_messages, :order => 'id desc', :dependent => :destroy, :conditions => "archived = 1", :class_name => 'ChatMessage'

  acts_as_list :scope => 'user_id = #{user_id}'
  
  def unread
    ChatMessage.count(:conditions => ["chat_id = ? AND id > ? AND archived = 0", self.id, self.last_seen.to_i])
  end
end
