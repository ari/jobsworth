class AddWorkLogIdToProjectFiles < ActiveRecord::Migration
  def self.up
    add_column :project_files, :work_log_id, :integer
  end

  def self.down
    remove_column :project_files, :work_log_id
  end
end
