class AddChannelUsers < ActiveRecord::Migration
  def self.up
    create_table :shout_channel_subscriptions do |t|
      t.column :shout_channel_id, :integer
      t.column :user_id, :integer
    end

    add_index :shout_channel_subscriptions, :shout_channel_id
    add_index :shout_channel_subscriptions, :user_id
  end

  def self.down
    remove_index :shout_channel_subscriptions, :user_id
    remove_index :shout_channel_subscriptions, :shout_channel_id

    drop_table :shout_channel_subscriptions
  end
end
