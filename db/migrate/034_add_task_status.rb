class AddTaskStatus < ActiveRecord::Migration
  def self.up
    add_column :tasks, :status, :integer, :default => 0
  end

  def self.down
    remove_column :tasks, :status
  end
end
