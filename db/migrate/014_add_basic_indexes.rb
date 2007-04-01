class AddBasicIndexes < ActiveRecord::Migration
  def self.up
    add_index :tasks, :component_id
    add_index :components, [:company_id, :project_id]
    add_index :components, :parent_id
    add_index :customers, [:company_id, :name]
    add_index :projects, :company_id
    add_index :projects, :customer_id
    add_index :work_logs, [:user_id, :task_id]#
    add_index :work_logs, [:task_id, :log_type]
    add_index :work_logs, :component_id
  end

  def self.down
    remove_index :tasks, :component_id
    remove_index :components, :company_id
    remove_index :components, :parent_id
    remove_index :customers, :company_id
    remove_index :projects, :company_id
    remove_index :projects, :customer_id
    remove_index :work_logs, :user_id
    remove_index :work_logs, :task_id
    remove_index :work_logs, :component_id
  end
end
