require "migration_helpers"

class AddResourceIndexes < ActiveRecord::Migration
  extend MigrationHelpers

  def self.up
    foreign_key(:resource_attributes, :resource_id, :resources)
    foreign_key(:resource_attributes, :resource_type_attribute_id, :resource_type_attributes)
    foreign_key(:resource_type_attributes, :resource_type_id, :resource_types)
  end

  def self.down
    remove_foreign_key(:resource_type_attributes, :resource_type_id, :resource_types)
    remove_foreign_key(:resource_attributes, :resource_type_attribute_id, :resource_type_attributes)
    remove_foreign_key(:resource_attributes, :resource_id, :resources)
  end
end
