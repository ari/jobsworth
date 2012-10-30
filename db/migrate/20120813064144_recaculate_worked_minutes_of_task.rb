class RecaculateWorkedMinutesOfTask < ActiveRecord::Migration
  def up
    # force recaculate task worked_minutes, as the unit of work log duration has changed from seconds to minutes
    # Note: can't use "update set worked_minutes=worked_minutes/60" because some records are already updated to minutes
    puts "Force recaculate task worked_minutes. This may take a while, please wait:"
    TaskRecord.all.each do |t|
      t.recalculate_worked_minutes
      t.save
    end
  end

  def down
  end
end
