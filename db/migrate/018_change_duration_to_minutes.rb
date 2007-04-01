class ChangeDurationToMinutes < ActiveRecord::Migration
  def self.up
    @tasks = Task.find(:all)
    @tasks.each { |t| 
      t.duration = t.duration * 60
      t.save
    }

  end

  def self.down
    @tasks = Task.find(:all)
    @tasks.each { |t| 
      t.duration = t.duration / 60
      t.save
    }
  end
end
