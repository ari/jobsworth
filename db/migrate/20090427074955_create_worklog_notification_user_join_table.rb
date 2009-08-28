class CreateWorklogNotificationUserJoinTable < ActiveRecord::Migration
  def self.up
    create_table :work_logs_notifications, :id => false do |t|
      t.column :work_log_id, :integer
      t.column :user_id, :integer
    end

    add_index(:work_logs_notifications, [ :work_log_id, :user_id ])
  end

  def self.down
    drop_table :work_logs_notifications
  end
end
