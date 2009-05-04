class ChangeAttributeValueColumnType < ActiveRecord::Migration
  def self.up
    change_column :custom_attribute_values, :value, :text
  end

  def self.down
  end
end
