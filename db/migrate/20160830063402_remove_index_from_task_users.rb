class RemoveIndexFromTaskUsers < ActiveRecord::Migration
  def change
    remove_foreign_key :task_users, :users
    remove_index :task_users, column: :user_id
  end
end
