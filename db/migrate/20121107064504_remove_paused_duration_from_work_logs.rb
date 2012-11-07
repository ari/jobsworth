class RemovePausedDurationFromWorkLogs < ActiveRecord::Migration
  def up
    remove_column :work_logs, :paused_duration
  end

  def down
    add_column :work_logs, :paused_duration, :integer
  end
end
