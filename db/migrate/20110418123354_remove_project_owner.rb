class RemoveProjectOwner < ActiveRecord::Migration
  def self.up
    remove_column :projects, :user_id
  end

  def self.down
    add_column :projects, :user_id, :integer
  end
end
