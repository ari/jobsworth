class CreateChatMessages < ActiveRecord::Migration
  def self.up
    create_table :chat_messages do |t|
      t.references :chat
      t.references :user
      t.string     :body
      t.timestamps
    end

    add_index :chat_messages, [:chat_id, :created_at]
    
  end

  def self.down
    drop_table :chat_messages
  end
end
