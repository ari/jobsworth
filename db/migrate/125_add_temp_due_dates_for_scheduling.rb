class AddTempDueDatesForScheduling < ActiveRecord::Migration
  def self.up
    add_column :tasks, :scheduled_at, :timestamp, :default => nil
    add_column :tasks, :scheduled_duration, :integer, :default => nil
    add_column :tasks, :scheduled, :boolean, :default => false
    
    add_column :milestones, :scheduled_at, :timestamp, :default => nil
    add_column :milestones, :scheduled, :boolean, :default => false
    
  end

  def self.down
    remove_column :milestones, :scheduled_at
    remove_column :tasks, :scheduled_duration
    remove_column :tasks, :scheduled_at
  end
end
