class RemoveSendNotifications < ActiveRecord::Migration
  def self.up
    remove_column :users, :send_notifications
  end

  def self.down
    add_column :users, :send_notifications, :integer, :default => 1
  end
end
