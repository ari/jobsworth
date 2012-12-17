class RemoveNewsletterAndShowTypeIconsFromUsers < ActiveRecord::Migration
  def up
    remove_column :users, :show_type_icons
    remove_column :users, :newsletter
  end

  def down
    add_column :users, :show_type_icons, :boolean, :default => true
    add_column :users, :newsletter, :integer, :default => 1
  end
end
