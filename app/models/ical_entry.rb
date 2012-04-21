# encoding: UTF-8
# Cached generated iCalendar entries, to speed up the feed generation

class IcalEntry < ActiveRecord::Base
  belongs_to :task, :class_name=>"AbstractTask", :foreign_key=>'task_id'
  belongs_to :work_log
end






# == Schema Information
#
# Table name: ical_entries
#
#  id          :integer(4)      not null, primary key
#  task_id     :integer(4)
#  work_log_id :integer(4)
#  body        :text
#
# Indexes
#
#  index_ical_entries_on_task_id      (task_id)
#  index_ical_entries_on_work_log_id  (work_log_id)
#

