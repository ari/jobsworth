class AddCustomerIdToUser < ActiveRecord::Migration
  def self.up
    add_column User.table_name, :customer_id, :integer
  end

  def self.down
    remove_column User.table_name, :customer_id
  end
end
