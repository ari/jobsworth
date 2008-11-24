# A single instant message between two users.

class ChatMessage < ActiveRecord::Base
  belongs_to :chat
  belongs_to :user
  
  acts_as_ferret({ :fields => { 'chat_id' => {},
                     'body' => { :boost => 1.5 }
                   }, :remote => true
  })

end
