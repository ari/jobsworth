class AddUploadUserId < ActiveRecord::Migration
  def self.up
    add_column :project_files, :user_id, :integer
  end

  def self.down
    remove_column :project_files, :user_id
  end
end
