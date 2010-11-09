class RemoveUnusedColumnsFromProjectFiles < ActiveRecord::Migration
  def self.up
    remove_column :project_files, :filename
    remove_column :project_files, :file_size
    remove_column :project_files, :file_type
  end

  def self.down
    add_column :project_files, :filename, :string
    add_column :project_files, :file_size, :integer
    add_column :project_files, :file_type, :integer, :default => 0
  end
end
