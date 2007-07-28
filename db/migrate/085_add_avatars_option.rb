class AddAvatarsOption < ActiveRecord::Migration
  def self.up
    add_column :users, :option_avatars, :integer, :default => 1
    execute('UPDATE users set option_avatars=1')
  end

  def self.down
    remove_column :users, :option_avatars
  end
end
