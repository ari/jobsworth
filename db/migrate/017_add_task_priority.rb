class AddTaskPriority < ActiveRecord::Migration
  def self.up
    add_column :tasks, :priority, :integer, :default => 0
    @tasks = Task.find(:all)
    @tasks.each { |t| 
      t.priority = 0
      t.save
    }
  end

  def self.down
    remove_column :tasks, :priority
  end
end
