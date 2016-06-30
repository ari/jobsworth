class ChangeWorkLogDurationUnitToMinute < ActiveRecord::Migration
  def up
    WorkLog.where('duration > 0').update_all('duration = duration/60')
  end

  def down
  end
end
