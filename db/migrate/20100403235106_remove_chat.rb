class RemoveChat < ActiveRecord::Migration
  def self.up
	drop_table :chats
  	drop_table :chat_messages
  	drop_table :shouts
  	drop_table :shout_channels
  	drop_table :shout_channel_subscriptions
  end

  def self.down
  end
end
