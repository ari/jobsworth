class RemoveUselessScheduledFields < ActiveRecord::Migration
  def up
    remove_column :tasks, :scheduled_at
    remove_column :tasks, :scheduled_duration
    remove_column :tasks, :scheduled

    remove_column :milestones, :scheduled_at
    remove_column :milestones, :scheduled
  end

  def down
  end
end
