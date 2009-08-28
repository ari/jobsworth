class CreateShouts < ActiveRecord::Migration
  def self.up
    create_table :shouts do |t|
    t.column :company_id, :integer
    t.column :user_id, :integer
    t.column :created_at, :timestamp
    t.column :body, :text
    end

    add_index :shouts, :created_at
  end

  def self.down
    drop_table :shouts
  end
end
