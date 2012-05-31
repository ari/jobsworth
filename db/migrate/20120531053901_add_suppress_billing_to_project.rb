class AddSuppressBillingToProject < ActiveRecord::Migration
  def up
    remove_column :projects, :neverBill
    add_column :projects, :suppressBilling, :boolean, :default => false, :null => false
  end

  def down
    add_column :projects, :neverBill, :boolean, :default => false, :null => false
    remove_column :projects, :suppressBilling
  end
end
