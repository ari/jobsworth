class CreateTaskPropertiesValueJoinTable < ActiveRecord::Migration
  def self.up
    create_table :task_property_values do |t|
      t.column :task_id, :integer
      t.column :property_id, :integer
      t.column :property_value_id, :integer
    end

    add_index :task_property_values, [ :task_id ]
    add_index :task_property_values, [ :property_id ]
  end

  def self.down
    drop_table :task_property_values
  end
end
