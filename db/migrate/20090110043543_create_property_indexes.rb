class CreatePropertyIndexes < ActiveRecord::Migration
  def self.up
    add_index(Property.table_name, :company_id)
    add_index(PropertyValue.table_name, :property_id)
  end

  def self.down
    remove_index(Property.table_name, :company_id)
    remove_index(PropertyValue.table_name, :property_id)
  end
end
