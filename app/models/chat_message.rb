# A single instant message between two users.

class ChatMessage < ActiveRecord::Base
  belongs_to :chat
  belongs_to :user

  def self.search(user, keys)
    conditions = []
    keys.each { |k| conditions << "chat_messages.id = #{ k.to_i }" }
    conditions << Search.search_conditions_for(keys, [ "chat_messages.body" ], :search_by_id => false)
    conditions = "(#{ conditions.join(" or ") })"
    return user.chat_messages.all(:conditions => conditions)
  end
  
end

# == Schema Information
#
# Table name: chat_messages
#
#  id         :integer(4)      not null, primary key
#  chat_id    :integer(4)
#  user_id    :integer(4)
#  body       :string(255)
#  created_at :datetime
#  updated_at :datetime
#  archived   :boolean(1)      default(FALSE)
#

