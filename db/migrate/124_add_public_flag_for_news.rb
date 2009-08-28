class AddPublicFlagForNews < ActiveRecord::Migration
  def self.up
    add_column :news_items, :portal, :boolean, :default => true
  end

  def self.down
    remove_column :news_items, :portal
  end
end
