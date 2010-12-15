class CreateEmailDeliveries < ActiveRecord::Migration
  def self.up
    create_table :email_deliveries do |t|
      t.integer :work_log_id
      t.integer :email_address_id
      t.string :status
      t.timestamps
    end
  end

  def self.down
    drop_table :email_deliveries
  end
end
