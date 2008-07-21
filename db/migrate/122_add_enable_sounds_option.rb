class AddEnableSoundsOption < ActiveRecord::Migration
  def self.up
    add_column :users, :enable_sounds, :boolean, :default => true
  end

  def self.down
    remove_column :users, :enable_sounds
  end
end
