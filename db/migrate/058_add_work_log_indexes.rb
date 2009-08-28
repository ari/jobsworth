class AddWorkLogIndexes < ActiveRecord::Migration
  def self.up
    add_index :work_logs, :project_id
    add_index :work_logs, :customer_id
  end

  def self.down
    remove_index :work_logs, :project_id
    remove_index :work_logs, :customer_id
  end
end
