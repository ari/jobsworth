class DropNotifications < ActiveRecord::Migration
  def self.up
    drop_table :notifications
    drop_table :task_owners
  end

  def self.down
    raise IrreversibleMigration
  end
end
