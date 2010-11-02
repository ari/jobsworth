class AddTriggersPermission < ActiveRecord::Migration
  def self.up
    add_column :users, :use_triggers, :boolean, :default=>false
  end

  def self.down
    remove_column :users, :use_triggers
  end
end
