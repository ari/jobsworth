class AddProjectFinePermissions < ActiveRecord::Migration
  def self.up
    add_column :project_permissions, :can_comment, :boolean, :default => false
    add_column :project_permissions, :can_work, :boolean, :default => false
    add_column :project_permissions, :can_report, :boolean, :default => false
    add_column :project_permissions, :can_create, :boolean, :default => false
    add_column :project_permissions, :can_edit, :boolean, :default => false
    add_column :project_permissions, :can_reassign, :boolean, :default => false
    add_column :project_permissions, :can_prioritize, :boolean, :default => false
    add_column :project_permissions, :can_close, :boolean, :default => false
    add_column :project_permissions, :can_grant, :boolean, :default => false
    add_column :project_permissions, :can_milestone, :boolean, :default => false

    execute("update project_permissions SET can_comment=1, can_work=1, can_report=1, can_create=1, can_edit=1, can_reassign=1, can_prioritize=1, can_close=1, can_grant=1, can_milestone=1")
    execute("update users set admin=1 where admin=0")

  end

  def self.down

    execute("update users set admin=0 where admin=1")

    remove_column :project_permissions, :can_comment
    remove_column :project_permissions, :can_work
    remove_column :project_permissions, :can_report
    remove_column :project_permissions, :can_create
    remove_column :project_permissions, :can_edit
    remove_column :project_permissions, :can_reassign
    remove_column :project_permissions, :can_prioritize
    remove_column :project_permissions, :can_close
    remove_column :project_permissions, :can_grant
    remove_column :project_permissions, :can_milestone

  end
end
