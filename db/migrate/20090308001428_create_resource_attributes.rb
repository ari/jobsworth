class CreateResourceAttributes < ActiveRecord::Migration
  def self.up
    create_table :resource_attributes do |t|
      t.integer :resource_id
      t.integer :resource_type_attribute_id
      t.string :value
      t.string :password

      t.timestamps
    end
  end

  def self.down
    drop_table :resource_attributes
  end
end
