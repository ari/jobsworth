class AddChoiceIdToCustomAttributeValue < ActiveRecord::Migration
  def self.up
    add_column :custom_attribute_values, :choice_id, :integer
  end

  def self.down
    remove_column :custom_attribute_values, :choice_id
  end
end
