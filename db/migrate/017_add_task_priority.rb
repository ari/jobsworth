class AddTaskPriority < ActiveRecord::Migration
  def self.up
    add_column :tasks, :priority, :integer, :default => 0
    @tasks = Task.all
    @tasks.each { |t| 
      t.priority = 0
      t.save
    }
  end

  def self.down
    remove_column :tasks, :priority
  end
end
