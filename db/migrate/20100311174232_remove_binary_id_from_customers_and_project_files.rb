class RemoveBinaryIdFromCustomersAndProjectFiles < ActiveRecord::Migration
  def self.up
    remove_column :customers, :binary_id
    remove_column :project_files, :binary_id
  end

  def self.down
    add_column :customers, :binary_id, :integer, :default=> 0
    add_column :project_files, :binary_id, :integer, :default=>0
  end
end
