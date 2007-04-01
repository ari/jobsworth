class AddTaskFiles < ActiveRecord::Migration
  def self.up
    add_column :project_files, :task_id, :integer
  end

  def self.down
    remove_column :project_files, :task_id
  end
end
