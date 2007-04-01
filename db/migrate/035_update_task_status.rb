class UpdateTaskStatus < ActiveRecord::Migration
  def self.up
    execute "UPDATE tasks SET status = 2 WHERE completed_at IS NOT NULL"
  end

  def self.down

  end
end
