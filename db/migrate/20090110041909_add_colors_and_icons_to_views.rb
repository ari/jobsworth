class AddColorsAndIconsToViews < ActiveRecord::Migration
  def self.up
    add_column View.table_name, :colors, :integer
    add_column View.table_name, :icons, :integer
  end

  def self.down
    remove_column View.table_name, :colors
    remove_column View.table_name, :icons
  end
end
