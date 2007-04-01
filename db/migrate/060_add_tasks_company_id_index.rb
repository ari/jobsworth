class AddTasksCompanyIdIndex < ActiveRecord::Migration
  def self.up
    add_index :tasks, :company_id
    remove_index :tasks, :component_id
  end

  def self.down
    add_index :tasks, :component_id
    remove_index :tasks, :company_id
  end
end
