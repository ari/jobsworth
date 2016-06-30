class RemoveProjectFolders < ActiveRecord::Migration
  def up
    # remove orphaned project files
    ProjectFile.where('task_id IS NULL').delete_all

    # remove project folder
    remove_column :project_files, :project_folder_id
    drop_table :project_folders
  end

  def down
  end
end
