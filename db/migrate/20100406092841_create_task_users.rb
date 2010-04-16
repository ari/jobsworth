class CreateTaskUsers < ActiveRecord::Migration
  def self.up
    create_table :task_users do |t|
      t.integer :user_id
      t.integer :task_id
      t.string  :type
      t.boolean :unread
      t.boolean :notified_last_change

      t.timestamps
    end
  end

  def self.down
    drop_table :task_users
  end
end
