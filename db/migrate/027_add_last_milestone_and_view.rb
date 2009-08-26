class AddLastMilestoneAndView < ActiveRecord::Migration
  def self.up
    add_column :users, :last_milestone_id, :integer
    add_column :users, :last_filter, :integer
  end

  def self.down
    remove_column :users, :last_milestone_id
    remove_column :users, :last_filter
  end
end
