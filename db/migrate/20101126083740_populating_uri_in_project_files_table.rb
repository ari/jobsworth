class PopulatingUriInProjectFilesTable < ActiveRecord::Migration
  def self.up
    self.execute("UPDATE project_files SET uri = CONCAT(id, '_', file_file_name) WHERE URI IS NULL")
    change_column_null(:project_files, :uri, false)
    remove_column(:project_files, :mime_type)
  end

  def self.down
    self.execute("UPDATE project_files SET uri = NULL")
    change_column_null(:project_files, :uri, true)
    add_column(:project_files, :mime_type, :string)
  end
end
