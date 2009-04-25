class AddActiveToUsersResourcesCustomers < ActiveRecord::Migration
  def self.up
    add_column :users, :active, :boolean, :default => true
    add_column :customers, :active, :boolean, :default => true
    add_column :resources, :active, :boolean, :default => true
  end

  def self.down
    remove_column :users, :active
    remove_column :customers, :active
    remove_column :resources, :active
  end
end
