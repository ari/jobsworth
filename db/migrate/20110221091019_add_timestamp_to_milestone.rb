class AddTimestampToMilestone < ActiveRecord::Migration
  def self.up
    add_column :milestones, :updated_at, :timestamp
    add_column :milestones, :created_at, :timestamp
  end

  def self.down
    remove_column :milestones, :updated_at
    remove_column :milestones, :created_at
  end
end
