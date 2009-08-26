class ChangeFoldersToActsAsTree < ActiveRecord::Migration
  def self.up
    remove_column :project_folders, :lft
    remove_column :project_folders, :rgt
    add_column :project_folders, :company_id, :integer
    remove_column :project_files, :project_folder_id
    add_column :project_files, :project_folder_id, :integer, :default => nil

    execute("update project_files set project_folder_id=null")

  end

  def self.down
    remove_column :project_files, :project_folder_id
    add_column :project_files, :project_folder_id, :integer, :default => 0
    execute("update project_files set project_folder_id=0")

    remove_column :project_folders, :company_id
    add_column :project_folders, :rgt, :integer
    add_column :project_folders, :lft, :integer
  end
end
