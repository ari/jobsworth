class AddStartedAtIndexToWorklogs < ActiveRecord::Migration
  def change
    add_index :work_logs, [:task_id, :started_at]
  end
end
