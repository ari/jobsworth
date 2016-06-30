class ScheduleTasks < ActiveRecord::Migration
  def up
    Rake::Task['jobsworth:schedule'].invoke
  end

  def down
  end
end
