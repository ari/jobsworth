class CreateCustomAttributeValues < ActiveRecord::Migration
  def self.up
    create_table :custom_attribute_values do |t|
      t.integer :custom_attribute_id
      t.integer :attributable_id
      t.string :attributable_type
      t.string :value

      t.timestamps
    end
  end

  def self.down
    drop_table :custom_attribute_values
  end
end
