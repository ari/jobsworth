class AddWorkLogApprovalFields < ActiveRecord::Migration
  def self.up
    add_column :work_logs, :exported, :datetime
    add_column :work_logs, :approved, :boolean
    add_column :users, :can_approve_work_logs, :boolean
  end

  def self.down
    remove_column :work_logs, :exported
    remove_column :work_logs, :approved
    remove_column :users, :can_approve_work_logs
  end
end
