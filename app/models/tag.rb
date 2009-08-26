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
    top_counts_as_tags(company).map { |tag, count| [ tag.name, count ] }
  end

  # Returns an array of tag counts grouped by tag.
  # Uses Tag.top_counts.
  def self.top_counts_as_tags(company, task_conditions = {})
    sql = "select tag_id, count(task_id) from task_tags group by tag_id"
    ids_and_counts = connection.select_rows(sql)

    res = ids_and_counts.map { |id, count| [ Tag.find(id), count.to_i ] }
    return res.sort_by { |tag, count| tag.name.downcase }
  end

end
