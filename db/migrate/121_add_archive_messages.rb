class AddArchiveMessages < ActiveRecord::Migration
  def self.up
    add_column :chat_messages, :archived, :boolean, :default => false
  end

  def self.down
    remove_column :chat_message, :archived
  end
end
