class ConvertEarlierWorkDurations < ActiveRecord::Migration
  def self.up
    execute("update work_logs set duration=duration * 60;")
    execute("update work_logs set paused_duration=paused_duration * 60;")
    execute("update sheets set paused_duration=paused_duration * 60;")
  end

  def self.down
    execute("update work_logs set duration=paused / 60;")
    execute("update work_logs set paused_duration=paused_duration / 60;")
    execute("update sheets set paused_duration=paused_duration / 60;")
  end
end
