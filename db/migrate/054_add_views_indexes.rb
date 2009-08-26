class AddViewsIndexes < ActiveRecord::Migration
  def self.up
    add_index :views, :company_id
  end

  def self.down
    remove_index :views, :company_id
  end
end
