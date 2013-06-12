class AddIndexOnWorkLogIdInEmailDeliveries < ActiveRecord::Migration
  def change
    add_index :email_deliveries, :work_log_id
  end
end
