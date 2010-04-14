class AddAccessLevelForUserAndWorkLog < ActiveRecord::Migration
  def self.up
    add_column :users, :access_level_id, :integer, :default=>1
    add_column :work_logs, :access_level_id, :integer, :default=>1
    AccessLevel.create!(:name=>'customer')
    AccessLevel.create!(:name=>'internal')
  end

  def self.down
    remove_column :users, :access_level_id
    remove_column :work_logs, :access_level_id
  end
end
