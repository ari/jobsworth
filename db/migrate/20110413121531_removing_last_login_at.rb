class RemovingLastLoginAt < ActiveRecord::Migration
  def self.up
  remove_column :users, :last_login_at
  end

  def self.down
    add_column :users, :last_login_at, :datetime
  end
end
