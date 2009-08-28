class RemoveOptionShowCalendar < ActiveRecord::Migration
  def self.up
    remove_column :users, :option_showcalendar
  end

  def self.down
    add_column :users, :option_showcalendar, :integer, :default => 1
  end
end
