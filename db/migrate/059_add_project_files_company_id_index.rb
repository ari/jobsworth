class AddProjectFilesCompanyIdIndex < ActiveRecord::Migration
  def self.up
    add_index :project_files, :company_id
  end

  def self.down
    remove_index :project_files, :company_id
  end
end
