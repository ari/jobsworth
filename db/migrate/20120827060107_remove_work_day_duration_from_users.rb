class RemoveWorkDayDurationFromUsers < ActiveRecord::Migration
  def up
    remove_column :users, :workday_duration
    remove_column :users, :days_per_week
    remove_column :users, :duration_format
  end

  def down
  end
end
