class AddUserFloatingChatOption < ActiveRecord::Migration
  def self.up
    add_column :users, :option_floating_chat, :boolean, :default => true
  end

  def self.down
    remove_column :users, :option_floating_chat
  end
end
