class IndexCompanyAndAttributes < ActiveRecord::Migration
  def self.up
	add_index :companies, :subdomain, :unique => true
	add_index :custom_attribute_values, ["attributable_id", "attributable_type"], :name => "by_attributables"
  end

  def self.down
  	remove_index :companies, :subdomain
	remove_index :custom_attribute_values, "by_attributables"
  end
end
