require 'migration_helpers'
class AddIndexesToTaskUsers < ActiveRecord::Migration
  extend MigrationHelpers

  def self.up
    foreign_key(:task_users, :user_id, :users)
    foreign_key(:task_users, :task_id, :tasks)
    add_index :task_users, :user_id
    add_index :task_users, :task_id
  end

  def self.down
    remove_foreign_key(:task_users, :user_id, :users)
    remove_foreign_key(:task_users, :user_id, :users)
    remove_index :task_users, :user_id
    remove_index :task_users, :task_id
  end
end
