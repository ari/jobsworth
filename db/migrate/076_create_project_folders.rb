class CreateProjectFolders < ActiveRecord::Migration
  def self.up
    create_table :project_folders do |t|
      t.column :name, :string
      t.column :project_id, :integer
      t.column :parent_id, :integer
      t.column :lft, :integer
      t.column :rgt, :integer
      t.column :created_at, :timestamp
    end

    add_column :project_files, :project_folder_id, :integer, :default => 0
    execute("update project_files set project_folder_id=0")
    add_index :project_folders, :project_id

  end

  def self.down
    remove_column :project_files, :project_folder_id
    drop_table :project_folders
  end
end
