class RecacheWorkedMinutes < ActiveRecord::Migration
  def self.up
    say_with_time "Caching Task worked_minutes" do
      Task.all.each do |t|
        mins = WorkLog.where("task_id = ?", t.id).sum(:duration).to_i / 60
        execute("update tasks set worked_minutes = #{mins} where id = #{t.id}")
      end
    end 
  end

  def self.down
  end
end
