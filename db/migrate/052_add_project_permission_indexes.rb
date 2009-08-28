class AddProjectPermissionIndexes < ActiveRecord::Migration
  def self.up
    add_index :project_permissions, :project_id
    add_index :project_permissions, :user_id
  end

  def self.down
    remove_index :project_permissions, :project_id
    remove_index :project_permissions, :user_id
  end
end
