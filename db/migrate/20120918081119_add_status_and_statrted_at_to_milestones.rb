class AddStatusAndStatrtedAtToMilestones < ActiveRecord::Migration
  def change
    add_column :milestones, :status, :integer
    add_column :milestones, :start_at, :datetime
  end
end
