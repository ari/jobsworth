class SetStatusForExistingMilestones < ActiveRecord::Migration
  def up
    Milestone.all.each do |m|
      if m.completed_at.nil?
        m.update_attributes(:status_name => :open)
      else
        m.update_attributes(:status_name => :closed)
      end
    end
  end

  def down
  end
end
