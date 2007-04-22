class AddWorkdayDuration < ActiveRecord::Migration
  def self.up
    add_column  :users, :workday_duration, :integer, :default => 480
    execute("UPDATE users SET workday_duration = 480;")
  end

  def self.down
    remove_column :users, :workday_duration
  end
end
