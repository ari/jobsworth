class DropTasksUserId < ActiveRecord::Migration
  def self.up
    remove_column :tasks, :user_id
  end

  def self.down
    add_column :tasks, :user_id, :integer
  end
end
