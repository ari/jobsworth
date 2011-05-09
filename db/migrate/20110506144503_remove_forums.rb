class RemoveForums < ActiveRecord::Migration
  def self.up
    drop_table :posts
    drop_table :topics
    drop_table :moderatorships
    drop_table :monitorships
    drop_table :forums
    remove_column :companies, :show_forum
    remove_column :projects, :create_forum
    remove_column :users, :posts_count
    
    # remove all forum change logs
    execute "DELETE FROM event_logs WHERE event_type = 60"
  end

  def self.down
    # pointless having a reverse here since we can't restore the data deleted
  end
end
