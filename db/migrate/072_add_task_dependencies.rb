class AddTaskDependencies < ActiveRecord::Migration
  def self.up
    create_table :dependencies, :id => false do |t|
      t.column :task_id, :integer
      t.column :dependency_id, :integer
    end
    add_index :dependencies, :task_id
    add_index :dependencies, :dependency_id
  end

  def self.down
    drop_table :dependencies
  end
end
