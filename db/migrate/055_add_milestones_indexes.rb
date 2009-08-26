class AddMilestonesIndexes < ActiveRecord::Migration
  def self.up
    add_index :milestones, :company_id
    add_index :milestones, :project_id
  end

  def self.down
    remove_index :milestones, :project_id
    remove_index :milestones, :company_id
  end
end
