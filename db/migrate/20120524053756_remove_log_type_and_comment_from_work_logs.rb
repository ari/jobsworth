class RemoveLogTypeAndCommentFromWorkLogs < ActiveRecord::Migration
  def up
    remove_column :work_logs, :comment
    remove_column :work_logs, :log_type
  end

  def down
    add_column :work_logs, :comment, :boolean
    add_column :work_logs, :log_type, :integer
  end
end
