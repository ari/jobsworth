class AddCanSeeUnwatchedToProjectPermission < ActiveRecord::Migration
  def self.up
    add_column :project_permissions, :can_see_unwatched, :boolean, :default=>true
  end

  def self.down
    remove_column :project_permissions, :can_see_unwatched
  end
end
