class IcalEntry < ActiveRecord::Base
  belongs_to :task
  belongs_to :work_log
end
