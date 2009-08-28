class AddReceiveOwnNotificationsToUser < ActiveRecord::Migration
  def self.up
    add_column(User.table_name, :receive_own_notifications, :boolean, :default => true)
  end

  def self.down
    remove_column(User.table_name, :receive_own_notifications)
  end
end
