class AddUserLastSeen < ActiveRecord::Migration
  def self.up
    add_column :users, :last_seen_at, :timestamp
  end

  def self.down
    remove_column :users, :last_seen_at
  end
end
