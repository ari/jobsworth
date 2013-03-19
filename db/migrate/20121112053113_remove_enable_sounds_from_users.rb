class RemoveEnableSoundsFromUsers < ActiveRecord::Migration
  def up
    remove_column :users, :enable_sounds
  end

  def down
    add_column :users, :enable_sounds, :boolean
  end
end
