class RemoveProjectOwner < ActiveRecord::Migration
  def self.up
    execute %{alter table projects drop foreign key fk_projects_user_id}    
    remove_column :projects, :user_id
  end

  def self.down
    add_column :projects, :user_id, :integer
  end
end