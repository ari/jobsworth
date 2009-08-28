class AddAutoCreateForumsOption < ActiveRecord::Migration
  def self.up
    add_column :projects, :create_forum, :boolean, :default => true
  end

  def self.down
    remove_column :projects, :create_forum
  end
end
