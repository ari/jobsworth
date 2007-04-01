class AddUserPing < ActiveRecord::Migration
  def self.up
    add_column :users, :last_ping_at, :timestamp
  end

  def self.down
    remove_column :users, :last_ping_at
  end
end
