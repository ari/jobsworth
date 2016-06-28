class ChangeDefaultReceiveOwnNotificationsValueInUsersToFalse < ActiveRecord::Migration
  def up
    change_column :users, :receive_own_notifications, :boolean, default: false
  end

  def down
    change_column :users, :receive_own_notifications, :boolean, default: true
  end
end
