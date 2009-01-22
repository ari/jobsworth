class AddSortAndColorToProperties < ActiveRecord::Migration
  def self.up
    add_column Property.table_name, :default_sort, :boolean
    add_column Property.table_name, :default_color, :boolean
  end

  def self.down
    remove_column Property.table_name, :default_sort
    remove_column Property.table_name, :default_color
  end
end
