require 'migration_helpers'
class CreateTaskFilterUsers < ActiveRecord::Migration
  extend MigrationHelpers
  
  def self.up
    create_table :task_filter_users do |t|
      t.integer :user_id
      t.integer :task_filter_id
      t.timestamps
    end
    
    foreign_key :task_filter_users, :user_id, :users
    foreign_key :task_filter_users, :task_filter_id, :task_filters
    add_index   :task_filter_users, :user_id
    add_index   :task_filter_users, :task_filter_id
    
    # make owner can see their own filters
    # create task filter status = 'show' for each task filter
    execute("INSERT INTO task_filter_users(`user_id`, `task_filter_id`, `created_at`, `updated_at`)
             SELECT task_filters.user_id, task_filters.id, now(), now() FROM task_filters 
             WHERE task_filters.system = 0 AND task_filters.recent_for_user_id IS NULL")
                        
  end

  def self.down
    drop_table :task_filter_users
  end
  
end
