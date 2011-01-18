class RemoveTasksRepeat < ActiveRecord::Migration
  def self.up
    remove_column :tasks, :repeat
  end

  def self.down
    add_column :tasks, :repeat, :string
  end
end
