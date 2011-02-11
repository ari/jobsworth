class TaskFilterUser < ActiveRecord::Base
  belongs_to :user
  belongs_to :task_filter
end
