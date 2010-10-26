class AddUserSeenNewsId < ActiveRecord::Migration
  def self.up
    add_column :users, :seen_news_id, :integer, :default => 0
    @users = User.all
    @users.each { |u| 
      u.seen_news_id = 0
      u.save
    }
  end

  def self.down
    remove_column :users, :seen_news_id
  end
end
