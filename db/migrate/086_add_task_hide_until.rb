class AddTaskHideUntil < ActiveRecord::Migration
  def self.up
    add_column :tasks, :hide_until, :timestamp
  end

  def self.down
    remove_column :task, :hide_until
  end
end
