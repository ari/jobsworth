class CreateResourceTypeAttributes < ActiveRecord::Migration
  def self.up
    create_table :resource_type_attributes do |t|
      t.integer :resource_type_id
      t.string :name
      t.boolean :is_mandatory
      t.boolean :allows_multiple
      t.boolean :is_password
      t.string :validation_regex
      t.integer :default_field_length
      t.integer :position

      t.timestamps
    end
  end

  def self.down
    drop_table :resource_type_attributes
  end
end
