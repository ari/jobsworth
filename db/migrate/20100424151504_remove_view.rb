class RemoveView < ActiveRecord::Migration
  def self.up
    drop_table :views
    drop_table :views_property_values
  end

  def self.down
   raise ActiveRecord::IrreversibleMigration, "Can't restore deleted views and views_property_values tables."
  end
end
