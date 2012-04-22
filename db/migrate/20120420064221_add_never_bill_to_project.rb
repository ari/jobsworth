class AddNeverBillToProject < ActiveRecord::Migration
  def change
    add_column :projects, :neverBill, :boolean
  end
end
