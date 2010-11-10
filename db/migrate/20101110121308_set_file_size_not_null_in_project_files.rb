class SetFileSizeNotNullInProjectFiles < ActiveRecord::Migration
  def self.up
    #deletes all files with file_size NULL
    ProjectFile.where("file_file_size IS NULL").each do |f|
      f.destroy
    end

    change_column_null(:project_files, :file_file_size, false)
  end

  def self.down
    change_column_null(:project_files, :file_file_size, true)
  end
end
