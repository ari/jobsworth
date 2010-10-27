class UpdateLogTypes < ActiveRecord::Migration
  def self.up
    logs = WorkLog.all
    logs.each do |l|
      old_type = l.log_type

      l.log_type = WorkLog::TASK_COMMENT if old_type == 2
      l.log_type = WorkLog::TASK_CREATED if old_type == 1 && l.body == "- Created"
      l.log_type = WorkLog::TASK_COMPLETED if old_type == 1 && l.body == "- Completed"
      l.log_type = WorkLog::TASK_REVERTED if old_type == 1 && l.body == "- Reverted"
      l.log_type = WorkLog::TASK_ARCHIVED if old_type == 1 && l.body == "- Archived"
      l.log_type = WorkLog::TASK_RESTORED if old_type == 1 && l.body == "- Restored"
      l.log_type = WorkLog::TASK_WORK_ADDED if old_type == 0

      l.log_type = WorkLog::TASK_MODIFIED if l.log_type == old_type && l.body != "- Created"

      l.body = "" if l.body == "- Created" || l.body == "- Completed" || l.body == "- Reverted" || l.body == "- Created" || l.body == "- Archived" || l.body == "- Restored"

      say "[#{l.id}] #{old_type} => #{l.log_type}"
      l.save

    end
  end

  def self.down
    logs = WorkLog.all
    logs.each do |l|
      l.log_type = 1 if l.log_type == WorkLog::TASK_CREATED
      l.log_type = 1 if l.log_type == WorkLog::TASK_COMPLETED
      l.log_type = 1 if l.log_type == WorkLog::TASK_REVERTED
      l.log_type = 1 if l.log_type == WorkLog::TASK_ARCHIVED
      l.log_type = 1 if l.log_type == WorkLog::TASK_REVERTED
      l.log_type = 2 if l.log_type == WorkLog::TASK_COMMENT
      l.log_type = 0 if l.log_type == WorkLog::TASK_WORK_ADDED
      l.save
    end

  end
end
