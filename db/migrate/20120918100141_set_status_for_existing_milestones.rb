class SetStatusForExistingMilestones < ActiveRecord::Migration
  def up
    Milestone.all.each do |m|
      if m.completed_at.nil?
        m.update_column(:status, 1)
      else
        m.update_column(:status, 3)
      end
    end
  end

  def down
  end
end