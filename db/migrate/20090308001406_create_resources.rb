class CreateResources < ActiveRecord::Migration
  def self.up
    create_table :resources do |t|
      t.integer :company_id
      t.integer :resource_type_id
      t.integer :parent_id
      t.string :name
      t.integer :customer_id
      t.text :notes

      t.timestamps
    end
  end

  def self.down
    drop_table :resources
  end
end
