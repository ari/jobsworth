class RemoveComponentReferences < ActiveRecord::Migration
  def self.up
    remove_index   "work_logs", ["component_id"]

    remove_column :tasks, :component_id
    remove_column :work_logs, :component_id

  end

  def self.down
    add_column  :tasks, :component_id, :integer, :default => 0
    add_column  :tasks, :component_id, :integer, :default => 0

    add_index "work_logs", ["component_id"], :name => "work_logs_component_id_index"

  end
end
