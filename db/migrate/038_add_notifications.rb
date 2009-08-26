class AddNotifications < ActiveRecord::Migration
  def self.up
    create_table :notifications do |t|
      t.column :task_id, :integer
      t.column :user_id, :integer
    end
  end

  def self.down
    drop_table :notifications
  end

end
