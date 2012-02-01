class AddIndexToEmailDelivery < ActiveRecord::Migration
  def up
    add_index :email_deliveries, :status
  end

  def down
    drop_index :email_deliveries, :status
  end
end
