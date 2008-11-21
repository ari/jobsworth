class CacheProjectTaskCounts < ActiveRecord::Migration
  def self.up
      add_column :projects, :open_tasks, :integer, :default => nil
      add_column :projects, :total_tasks, :integer, :default => nil
  end

  def self.down
      remove_column :projects, :total_tasks
      remove_column :projects, :open_tasks
  end
end
