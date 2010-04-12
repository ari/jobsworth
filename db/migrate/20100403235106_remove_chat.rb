class RemoveChat < ActiveRecord::Migration
  def self.up
	drop_table :chats
  	drop_table :chat_messages
  	drop_table :shouts
  	drop_table :shout_channels
  	drop_table :shout_channel_subscriptions
  	
  	remove_column :companies, :restricted_userlist
  	remove_column :companies, :show_messaging
  	remove_column :companies, :show_chat
  end

  def self.down
    raise ActiveRecord::IrreversibleMigration, "Can't restore deleted chat tables."
  end
end
