require "migration_helpers"

class AddIndexesToCustomAttributes < ActiveRecord::Migration
  extend MigrationHelpers

  def self.up
    add_index(:custom_attribute_values, :custom_attribute_id)
    add_index(:custom_attribute_values, [ :attributable_id, :attributable_type ], 
              :name => "by_attributables")
    add_index(:custom_attributes, [ :company_id, :attributable_type ])
    add_index(:custom_attribute_choices, :custom_attribute_id)
  end

  def self.down
    remove_index(:custom_attribute_choices, :custom_attribute_id)
    remove_index(:custom_attributes, [ :company_id, :attributable_type ])
    remove_index(:custom_attribute_values, :name => "by_attributables")
    remove_index(:custom_attribute_values, :custom_attribute_id)
  end
end
