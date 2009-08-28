class AddIconUrlToPropertyValues < ActiveRecord::Migration
  def self.up
    add_column PropertyValue.table_name, :icon_url, :string, :limit => 1000
  end

  def self.down
    remove_column PropertyValue.table_name, :icon_url
  end
end
