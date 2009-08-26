class CreateOrganizationalUnits < ActiveRecord::Migration
  def self.up
    create_table :organizational_units do |t|
      t.integer :customer_id

      t.timestamps
    end
  end

  def self.down
    drop_table :organizational_units
  end
end
