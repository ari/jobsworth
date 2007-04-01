class AddWorkLogsCompanyIdIndex < ActiveRecord::Migration
  def self.up
    add_index :work_logs, :company_id
  end

  def self.down
    remove_index :work_logs, :company_id
  end
end
