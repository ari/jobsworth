class PriorityFix < ActiveRecord::Migration
  def self.up
    Task.all.each { |t| 
      t.priority = -1 if t.priority == 1
      t.save
    }
  end

  def self.down
    Task.all.each { |t| 
      t.priority = 2 if t.priority == 1
      t.priority = 1 if t.priority == -1
      t.priority = 1 if t.priority == -2
      t.save
    }
  end
end
