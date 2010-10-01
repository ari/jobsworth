class TaskUsersTypeDafaultIsTaskOwner < ActiveRecord::Migration
  def self.up
    change_column :task_users, :type, :string, :default=>'TaskOwner'
  end

  def self.down
    change_column :task_users, :type, :string, :default=> nil
  end
end
