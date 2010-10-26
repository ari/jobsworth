class CacheWorkedDuration < ActiveRecord::Migration
  def self.up
    Task.record_timestamps = false

    add_column :tasks, :worked_minutes, :integer, :default => 0

    say_with_time "Caching Task worked_minutes" do
      Task.all.each do |t|
        t.worked_minutes = WorkLog.where("task_id = ?", t.id).sum(:duration).to_i / 60
        t.save
      end
    end 
    
  end

  def self.down
    drop_column :tasks, :worked_minutes
  end
end
