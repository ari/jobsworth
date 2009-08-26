class CacheProjectMilestoneCounts < ActiveRecord::Migration
  def self.up
    add_column :projects, :total_milestones, :integer, :default => nil
    add_column :projects, :open_milestones, :integer, :default => nil
  end

  def self.down
    remove_column :projects, :open_milestones
    remove_column :projects, :total_milestones
  end
end
