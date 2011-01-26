class AddUsernameOrEmailToEmailDeliveries < ActiveRecord::Migration
  def self.up
    add_column :email_deliveries, :username_or_email, :string
  end

  def self.down
    remove_column :email_deliveries, :username_or_email
  end
end
