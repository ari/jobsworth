# A user who is assigned to a task 
class TaskOwner < ActiveRecord::Base
  belongs_to :user
  belongs_to :task
end
