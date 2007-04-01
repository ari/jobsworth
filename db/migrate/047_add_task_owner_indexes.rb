class AddTaskOwnerIndexes < ActiveRecord::Migration
  def self.up
  	 add_index :task_owners, :user_id
	 add_index :task_owners, :task_id
  end

  def self.down
  	 remove_index :task_owners, :user_id
	 remove_index :task_owners, :task_id
  end
end
