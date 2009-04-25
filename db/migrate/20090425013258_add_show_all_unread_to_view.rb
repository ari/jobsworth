class AddShowAllUnreadToView < ActiveRecord::Migration
  def self.up
    add_column :views, :show_all_unread, :boolean, :default => false
  end

  def self.down
    remove_column :views, :show_all_unread
  end
end
