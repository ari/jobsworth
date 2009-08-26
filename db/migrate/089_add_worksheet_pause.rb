class AddWorksheetPause < ActiveRecord::Migration
  def self.up
    add_column :sheets, :paused_at, :timestamp
    add_column :sheets, :paused_duration, :integer, :default => 0

    add_column :work_logs, :paused_duration, :integer, :default => 0
  end

  def self.down
    drop_column :work_logs, :paused_duration

    drop_column :sheets, :paused_at
    drop_column :sheets, :paused_duration
  end
end
