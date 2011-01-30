class RemoveEmailDeliveryEmailAddressAssociation < ActiveRecord::Migration
  def self.up
    remove_column :email_deliveries, :email_address_id
  end

  def self.down
    add_column    :email_deliveries, :email_address_id, :integer
  end
end
