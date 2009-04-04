class AddTaskResourceJoinTable < ActiveRecord::Migration
  def self.up
    create_table(:resources_tasks, :id => false) do |t|
      t.column :resource_id, :integer
      t.column :task_id, :integer
    end

    add_index :resources_tasks, [ :task_id ]
    add_index :resources_tasks, [ :resource_id ]
  end

  def self.down
    drop_table :resources_tasks
  end
end
