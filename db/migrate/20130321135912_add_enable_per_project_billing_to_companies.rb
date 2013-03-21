class AddEnablePerProjectBillingToCompanies < ActiveRecord::Migration
  def self.up
    add_column :companies, :enable_per_project_billing, :boolean, :default => true
  end

  def self.down
    remove_column :companies, :enable_per_project_billing
  end
end
