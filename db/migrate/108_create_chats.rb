class CreateChats < ActiveRecord::Migration
  def self.up
    create_table :chats do |t|
      t.references :user
      t.references :target
      t.integer    :active, :default => 1
      t.integer    :position, :default => 0
      t.integer    :last_seen, :default => 0
      t.timestamps
    end
    
    add_index :chats, [:user_id, :target_id]
    add_index :chats, [:user_id, :position]
  end

  def self.down
    drop_table :chats
  end
end
