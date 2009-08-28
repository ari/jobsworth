class AddTaskRepeat < ActiveRecord::Migration
  def self.up
    add_column :tasks, :repeat, :string
  end

  def self.down
    remove_column :tasks, :repeat
  end
end
