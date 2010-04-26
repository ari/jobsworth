class RemoveNotifiedLastChange < ActiveRecord::Migration
  def self.up
    remove_column :task_users, :notified_last_change
  end

  def self.down
    add_column :task_users, :notified_last_change, :boolean, :default => true
  end
end
