class AddUnreadToTaskFilter < ActiveRecord::Migration
  def self.up
    add_column :task_filters, :unread_only, :boolean, :default => false
  end

  def self.down
    remove_column :task_filters, :unread_only
  end
end
