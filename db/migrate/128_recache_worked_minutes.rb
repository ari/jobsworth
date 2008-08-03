class RecacheWorkedMinutes < ActiveRecord::Migration
  def self.up
    say_with_time "Caching Task worked_minutes" do
      Task.find(:all).each do |t|
        mins = WorkLog.sum(:duration, :conditions => ["task_id = ?", t.id]).to_i / 60
        execute("update tasks set worked_minutes = #{mins} where id = #{t.id}")
      end
    end 
  end

  def self.down
  end
end
