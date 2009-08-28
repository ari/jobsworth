class AddWeekDaysOption < ActiveRecord::Migration
  def self.up
    add_column :users, :days_per_week, :integer, :default => 5
  end

  def self.down
    remove_column :users, :days_per_week
  end
end
