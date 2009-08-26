class AddProjectAndMilestoneCompletedAt < ActiveRecord::Migration
  def self.up
    add_column :milestones, :completed_at, :timestamp
    add_column :projects, :completed_at, :timestamp
  end

  def self.down
    remove_column :projects, :completed_at
    remove_column :milestones, :completed_at
  end
end
