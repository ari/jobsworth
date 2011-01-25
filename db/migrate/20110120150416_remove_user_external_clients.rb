class RemoveUserExternalClients < ActiveRecord::Migration
  def self.up
    remove_column :users, :option_externalclients
  end

  def self.down
    add_column :users, :option_externalclients, :integer
  end
end
