class ChangeWorkLogApprovedFromBooleanToInt < ActiveRecord::Migration
  def self.up
    change_column :work_logs, :approved, :integer, :default=>0
    rename_column :work_logs, :approved, :status
  end

  def self.down
    rename_column :work_logs, :status, :approved
    change_column :work_logs, :approved, :boolean, :default=>nil
  end
end
