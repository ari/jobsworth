class IndexTaskPropertyValues < ActiveRecord::Migration
  def self.up
	add_index(:task_property_values, [:task_id, :property_id ], :name => "task_property", :unique => true)
    remove_index(:task_property_values, "property_id")
    remove_index(:task_property_values, "task_id")
  end

  def self.down
    remove_index(:task_property_values, "task_property")
    add_index(:task_property_values, :task_id, :name => "task_id")
    add_index(:task_property_values, :property_id, :name => "property_id")
    end
end
