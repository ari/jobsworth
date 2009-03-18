class AddUseResourcesOptionToUsers < ActiveRecord::Migration
  def self.up
    add_column User.table_name, :use_resources, :boolean
  end

  def self.down
    remove_column User.table_name, :use_resources
  end
end
