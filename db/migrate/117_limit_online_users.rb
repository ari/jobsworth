class LimitOnlineUsers < ActiveRecord::Migration
  def self.up
    add_column :companies, :restricted_userlist, :boolean, :default => false
  end

  def self.down
    remove_column :companies, :restricted_userlist
  end
end
