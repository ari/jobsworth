class MigrateToTaskUsers < ActiveRecord::Migration
  def self.up
    say_with_time "Copying task watchers and owners to task_user" do
      execute " insert into task_users (task_id, user_id, unread, created_at, updated_at, notified_last_change, type) select task_id,user_id, unread, NOW(), NOW(), notified_last_change, 'TaskWatcher' from notifications where (notifications.task_id, notifications.user_id) not in (select task_id, user_id from task_owners);"

     execute " insert into task_users (task_id, user_id, unread, created_at, updated_at, notified_last_change, type) select distinct task_id,user_id, unread, NOW(), NOW(), notified_last_change, 'TaskOwner'  from task_owners;"

    end
  end

  def self.down
    execute "delete from task_users"
  end
end
