class ViewsHideDependencies < ActiveRecord::Migration
  def self.up
    add_column :views, :hide_dependencies, :integer
  end

  def self.down
    remove_column :views, :hide_dependencies
  end


end
