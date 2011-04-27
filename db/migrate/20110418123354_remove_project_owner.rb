require 'migration_helpers'

class RemoveProjectOwner < ActiveRecord::Migration
  extend MigrationHelpers
  def self.up
    remove_foreign_key :projects, :users           
    remove_column :projects, :user_id
  end

  def self.down
    add_column :projects, :user_id, :integer
  end
end