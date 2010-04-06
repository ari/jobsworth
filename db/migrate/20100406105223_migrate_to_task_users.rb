class MigrateToTaskUsers < ActiveRecord::Migration
  def self.up
    say_with_time "Copying task watchers and owners to task_user" do
      Task.all.each do |task|
        task.notifications.each do |n|
          TaskUser.new(:user_id=>n.user_id, :task_id=>n.task_id,:unread=>n.unread, :notified_last_change=>n.notified_last_change).save!
        end
        task.task_owners.each do |o|
          tu=TaskUser.find_or_create_by_task_id_and_user_id(o.task_id, o.user_id)
          tu.owner=true
          tu.unread=o.unread
          tu.notified_last_change=o.notified_last_change
          tu.save!
        end
      end
    end
  end

  def self.down
  end
end
