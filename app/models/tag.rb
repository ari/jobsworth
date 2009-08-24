# A tag belonging to a company and task

class Tag < ActiveRecord::Base

  belongs_to :company
  has_and_belongs_to_many      :tasks, :join_table => :task_tags

  def count
    tasks.count(:conditions => "tasks.completed_at IS NULL")
  end

  def total_count
    tasks.count
  end

  def to_s
    self.name
  end

end
