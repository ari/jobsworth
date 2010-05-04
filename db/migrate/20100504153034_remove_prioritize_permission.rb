class RemovePrioritizePermission < ActiveRecord::Migration
  def self.up
    remove_column :project_permissions, :can_prioritize
  end

  def self.down
    add_column :project_permissions, :can_prioritize, :boolean, :default=>false
  end
end
