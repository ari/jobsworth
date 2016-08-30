class AddCompoundIndexToTaskUsers < ActiveRecord::Migration
  def change
    add_index :task_users, [:user_id, :unread]
  end
end
