class WorkLogToEventLog < ActiveRecord::Migration
  def self.up
    WorkLog.order("id").each do |w|
      say "Importing work_log[#{w.id}]"
      l = w.create_event_log
      l.company_id = w.company_id
      l.project_id = w.project_id
      l.user_id = w.user_id
      l.event_type = w.log_type
      l.created_at = w.started_at
      l.save
    end
  end

  def self.down
    execute("TRUNCATE TABLE event_logs")
  end
end
