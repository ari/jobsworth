class WorkLogNotification < ActiveRecord::Base
  set_table_name "work_logs_notifications"

  belongs_to :user
  belongs_to :work_log
end
