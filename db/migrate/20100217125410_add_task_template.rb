class AddTaskTemplate < ActiveRecord::Migration
  def self.up
    add_column :tasks, :template, :boolean, :default=>false
  end

  def self.down
    remove_column :tasks, :template
  end
end
