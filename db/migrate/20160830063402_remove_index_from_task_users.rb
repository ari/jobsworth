class RemoveIndexFromTaskUsers < ActiveRecord::Migration
  def change
    remove_index :task_users, column: :user_id
  end
end
