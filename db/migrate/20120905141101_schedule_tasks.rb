class ScheduleTasks < ActiveRecord::Migration
  def up
    Rake::TaskRecord["jobsworth:schedule"].invoke
  end

  def down
  end
end
