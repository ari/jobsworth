class AddIdToWorkLogsNotifications < ActiveRecord::Migration
  def self.up
    add_column(:work_logs_notifications, :id, :primary_key)
  end

  def self.down
    remove_column(:work_logs_notifications, :id, :primary_key)
  end
end
