class ChangeDurationToMinutes < ActiveRecord::Migration
  def self.up
    @tasks = TaskRecord.all
    @tasks.each { |t| 
      t.duration = t.duration * 60
      t.save
    }

  end

  def self.down
    @tasks = TaskRecord.all
    @tasks.each { |t| 
      t.duration = t.duration / 60
      t.save
    }
  end
end
