# A single instant message between two users.

class ChatMessage < ActiveRecord::Base
  belongs_to :chat
  belongs_to :user

  def self.search(user, keys)
    conditions = []
    keys.each { |k| conditions << "chat_messages.id = #{ k.to_i }" }
    conditions << Search.search_conditions_for(keys, [ "chat_messages.body" ], false)
    conditions = "(#{ conditions.join(" or ") })"
    return user.chat_messages.all(:conditions => conditions)
  end
  
end
