class AddWaitForCustomerOptionToTask < ActiveRecord::Migration
  def self.up
    add_column :tasks, :wait_for_customer, :boolean, :default => false
  end

  def self.down
    remove_column :tasks, :wait_for_customer
  end
end
