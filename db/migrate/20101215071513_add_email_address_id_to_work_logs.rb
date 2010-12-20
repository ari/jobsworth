class AddEmailAddressIdToWorkLogs < ActiveRecord::Migration
  def self.up
    add_column :work_logs, :email_address_id, :integer
  end

  def self.down
    remove_column :work_logs, :email_address_id
  end
end
