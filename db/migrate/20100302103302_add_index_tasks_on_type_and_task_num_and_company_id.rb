class AddIndexTasksOnTypeAndTaskNumAndCompanyId < ActiveRecord::Migration
  def self.up
    remove_index :tasks, [:task_num, :company_id]
    add_index :tasks, [:type, :task_num, :company_id],:name => :index_tasks_on_type_and_task_num_and_company_id, :unique => true
  end

  def self.down
    remove_index :tasks, [:type, :task_num, :company_id]
    add_index :tasks, [:task_num, :company_id], :name => :index_tasks_on_task_num_and_company_id, :unique => true

  end
end
