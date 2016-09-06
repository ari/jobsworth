class AddCompoundIndexToTaskUsers < ActiveRecord::Migration
  def change
    add_index :task_users, [:user_id, :unread]
    add_foreign_key :task_users, :users
  end
end
