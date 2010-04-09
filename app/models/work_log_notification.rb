class WorkLogNotification < ActiveRecord::Base
  set_table_name "work_logs_notifications"

  belongs_to :user
  belongs_to :work_log
end


# == Schema Information
#
# Table name: work_logs_notifications
#
#  work_log_id :integer(4)
#  user_id     :integer(4)
#  id          :integer(4)      not null, primary key
#
# Indexes
#
#  index_work_logs_notifications_on_work_log_id_and_user_id  (work_log_id,user_id)
#  fk_work_logs_notifications_user_id                        (user_id)
#

