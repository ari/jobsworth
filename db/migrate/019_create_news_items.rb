class CreateNewsItems < ActiveRecord::Migration
  def self.up
    create_table :news_items do |t|
      t.column :created_at, :timestamp
      t.column :body, :text
    end
  end

  def self.down
    drop_table :news_items
  end
end
