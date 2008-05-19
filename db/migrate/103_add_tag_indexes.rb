class AddTagIndexes < ActiveRecord::Migration
  def self.up
    add_index :tags, [:company_id, :name]
  end

  def self.down
    remove_index :tags, [:company_id, :name]
  end
end
