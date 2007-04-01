class Milestone < ActiveRecord::Base
  belongs_to :company
  belongs_to :project
  belongs_to :user

  has_many :tasks, :dependent => :nullify

  def completed_tasks
    completed = Task.count( ["milestone_id = ? AND completed_at is not null", self.id] ) * 1.0
  end
  def total_tasks
    total = Task.count( ["milestone_id = ?", self.id] ) * 1.0
  end

  def percent_complete
    p = 0.0

    complete = self.completed_tasks
    total =  self.total_tasks

    p = (complete / total) * 100.0
  end

  def complete?
    self.completed_tasks == self.total_tasks
  end

end
