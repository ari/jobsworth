class AddTaskCreatedBy < ActiveRecord::Migration
  def self.up
    add_column :tasks, :updated_by_id, :integer
    add_column :components, :updated_by_id, :integer
  end

  def self.down
    remove_column :tasks, :updated_by_id
    remove_column :components, :updated_by_id
  end
end
