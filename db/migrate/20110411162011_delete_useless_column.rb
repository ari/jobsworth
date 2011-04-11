class DeleteUselessColumn < ActiveRecord::Migration
  def self.up
  remove_column :users, :email
  remove_column :users, :password
  end

  def self.down
  end
end
