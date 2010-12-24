# encoding: UTF-8
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

