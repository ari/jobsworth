class AddWorkLogType < ActiveRecord::Migration
  def self.up
    add_column :work_logs, :log_type, :integer, :default => 0
  end

  def self.down
    remove_column :work_logs, :log_type
  end
end
