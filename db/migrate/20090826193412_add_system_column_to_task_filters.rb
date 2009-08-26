class AddSystemColumnToTaskFilters < ActiveRecord::Migration
  def self.up
    add_column :task_filters, :system, :boolean, :default => false
  end

  def self.down
    remove_column :task_filters, :system
  end
end
