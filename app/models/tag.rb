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

  # Returns an array of tag counts grouped by name for the given company
  # All tags are retured by default - include task_conditions if you 
  # need to restrict those counts
  def self.top_counts(company, task_conditions = {})
    company.tags.count(:group => "tags.name",
                       :include => :tasks,
                       :conditions => task_conditions, 
                       :order => "tags.name asc")
  end

end
