class RenameMd5AndRemoveNameFromProjectFiles < ActiveRecord::Migration
  def self.up
    rename_column :project_files, :md5, :uri
    remove_column :project_files, :name
  end

  def self.down
    rename_column :project_files, :uri, :md5
    add_column :project_files, :name, :string
  end
end
