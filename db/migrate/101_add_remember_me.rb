class AddRememberMe < ActiveRecord::Migration
  def self.up
    add_column :users, :remember_until, :timestamp
  end

  def self.down
    remove_column :users, :remember_until
  end
end
