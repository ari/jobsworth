class AddEmailDeliveryUserAssociation < ActiveRecord::Migration
  def self.up
    remove_column :email_deliveries, :username_or_email
    add_column :email_deliveries, :email, :string
    add_column :email_deliveries, :user_id, :integer
    execute("UPDATE email_deliveries SET email=(select email_addresses.email from email_addresses where email_addresses.id= email_deliveries.email_address_id), user_id=(select email_addresses.user_id from email_addresses where email_addresses.id= email_deliveries.email_address_id)")
  end

  def self.down
    add_column :email_deliveries, :username_or_email, :string
    remove_column :email_deliveries, :email
    remove_column :email_deliveries, :user_id
  end
end
