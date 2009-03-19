class AddUnreadFlagToOwnersAndNotifications < ActiveRecord::Migration
  def self.up
    add_column TaskOwner.table_name, :unread, :boolean, :default => false
    add_column Notification.table_name, :unread, :boolean, :default => false
  end

  def self.down
    remove_column TaskOwner.table_name, :unread
    remove_column Notification.table_name, :unread
  end
end
