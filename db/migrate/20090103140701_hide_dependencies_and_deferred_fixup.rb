class HideDependenciesAndDeferredFixup < ActiveRecord::Migration
  def self.up
    rename_column :views, :hide_dependencies, :hide_deferred
    add_column    :views, :hide_dependencies, :integer
  end

  def self.down
    remove_column :views, :hide_dependencies
    rename_column :views, :hide_deferred, :hide_dependencies
  end
end
