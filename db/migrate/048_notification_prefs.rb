class NotificationPrefs < ActiveRecord::Migration
  def self.up
    add_column :users, :send_notifications, :integer, :default => 1
    add_column :users, :receive_notifications, :integer, :default => 1

    execute "update users set send_notifications=1,receive_notifications=1"

  end

  def self.down
    remove_column :users, :send_notifications
    remove_column :users, :receive_notifications
  end
end
