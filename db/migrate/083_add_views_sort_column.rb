class AddViewsSortColumn < ActiveRecord::Migration
  def self.up
    add_column :views, :sort, :integer, :default => 0
  end

  def self.down
    remove_column :views, :sort
  end
end
