class TimeRange < ActiveRecord::Base
  validates_presence_of :name
  validates_uniqueness_of :name

  # Returns the current start time (based on the ruby in 
  # the start column)
  def start_time
    eval(start) if start.present?
  end

  # Returns the current end time (based on the ruby in 
  # the end column)
  def end_time
    eval(self.end) if self.end.present?
  end

  def to_s
    name
  end
end
