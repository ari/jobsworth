class AddColumnsToOrganizationalUnits < ActiveRecord::Migration
  def self.up
    add_column :organizational_units, :name, :string
    add_column :organizational_units, :active, :boolean, :default => true
  end

  def self.down
    remove_column :organizational_units, :name
    remove_column :organizational_units, :active
  end
end
