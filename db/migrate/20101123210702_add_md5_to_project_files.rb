class AddMd5ToProjectFiles < ActiveRecord::Migration
  def self.up
    add_column :project_files, :md5, :string
  end

  def self.down
    remove_column :project_files, :md5
  end
end
