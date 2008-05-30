class Chat < ActiveRecord::Base
  belongs_to :user
  belongs_to :target, :class_name => 'User'
  has_many   :chat_messages, :order => 'id desc', :limit => 20

  acts_as_list :scope => 'user_id = #{user_id}'
end
