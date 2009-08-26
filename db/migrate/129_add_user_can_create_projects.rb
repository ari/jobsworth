class AddUserCanCreateProjects < ActiveRecord::Migration
  def self.up
    add_column :users, :create_projects, :boolean, :default => true
  end

  def self.down
    remove_column :users, :create_projects
  end
end
