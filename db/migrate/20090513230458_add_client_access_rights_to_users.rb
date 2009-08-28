class AddClientAccessRightsToUsers < ActiveRecord::Migration
  def self.up
    add_column :users, :read_clients, :boolean, :default => false
    add_column :users, :create_clients, :boolean, :default => false
    add_column :users, :edit_clients, :boolean, :default => false
  end

  def self.down
    remove_column :users, :read_clients
    remove_column :users, :create_clients
    remove_column :users, :edit_clients
  end
end
