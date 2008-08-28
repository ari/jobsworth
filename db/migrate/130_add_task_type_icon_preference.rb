class AddTaskTypeIconPreference < ActiveRecord::Migration
  def self.up
    add_column :users, :show_type_icons, :boolean, :default => true
  end

  def self.down
    remove_column :users, :show_type_icons
  end
end
