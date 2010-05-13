class MoveScmChangesetFromWorkLogToTask < ActiveRecord::Migration
  def self.up
    remove_column :work_logs, :scm_changeset_id
    add_column :scm_changesets, :task_id, :integer
  end

  def self.down
    add_column :work_logs, :scm_changeset_id, :integer
    remove_column :scm_changesets, :task_id
  end
end
