class AddWorkedNiceOption < ActiveRecord::Migration
  def self.up
    add_column :users, :duration_format, :integer, :default => 0
    execute("update users set duration_format = 0")
  end

  def self.down
    remove_column :users, :duration_format
  end
end
