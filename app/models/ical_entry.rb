# Cached generated iCalendar entries, to speed up the feed generation

class IcalEntry < ActiveRecord::Base
  belongs_to :task, :touch => true
  belongs_to :work_log
end
