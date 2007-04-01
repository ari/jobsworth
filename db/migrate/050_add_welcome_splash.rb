class AddWelcomeSplash < ActiveRecord::Migration
  def self.up
    add_column :users, :seen_welcome, :integer, :default => 0

    execute("update users set seen_welcome = 1")
  end

  def self.down
    remove_column :users, :seen_welcome
  end
end
