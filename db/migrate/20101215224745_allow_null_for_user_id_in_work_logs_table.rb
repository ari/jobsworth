class AllowNullForUserIdInWorkLogsTable < ActiveRecord::Migration
  def self.up
    change_column_null(:work_logs, :user_id, true)
  end

  def self.down
    change_column_null(:work_logs, :user_id, false)
  end
end
