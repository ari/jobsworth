class AddNotifiedLastChangeForTaskUsers < ActiveRecord::Migration
  def self.up
    add_column :task_owners, :notified_last_change, :boolean, :default => true
    add_column :notifications, :notified_last_change, :boolean, :default => true
  end

  def self.down
    remove_column :task_owners, :notified_last_change
    remove_column :notifications, :notified_last_change
  end
end
