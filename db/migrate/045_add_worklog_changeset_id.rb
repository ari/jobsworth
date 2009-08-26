class AddWorklogChangesetId < ActiveRecord::Migration
  def self.up
    add_column :work_logs, :scm_changeset_id, :integer
  end

  def self.down
    execute("delete from work_logs where log_type = #{WorkLog::SCM_COMMIT}")
    remove_column :work_logs, :scm_changeset_id
  end
end
