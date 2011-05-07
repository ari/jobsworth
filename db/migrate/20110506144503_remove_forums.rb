class RemoveForums < ActiveRecord::Migration
  def self.up
    drop_table :posts
    drop_table :topics
    drop_table :moderatorships
    drop_table :monitorships
    drop_table :forums
    remove_column :company, :show_forum
    remove_column :project, :create_forum
  end

  def self.down
    # pointless having a reverse here since we can't restore the data deleted
  end
end
