class AddCompaniesSuppressedEmailAddresses < ActiveRecord::Migration
  def self.up
    add_column :companies, :suppressed_email_addresses, :string
  end

  def self.down
    remove_column :companies, :suppressed_email_addresses
  end
end
