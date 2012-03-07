class RemoveContactEmailFromCustomer < ActiveRecord::Migration
  def up
    remove_column :customers, :contact_email
  end

  def down
  end
end
