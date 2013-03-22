class AddUseBillingToCompanies < ActiveRecord::Migration
  def self.up
    add_column :companies, :use_billing, :boolean, :default => true
  end

  def self.down
    remove_column :companies, :use_billing
  end
end
