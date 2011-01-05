# encoding: UTF-8
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

  DEFAULTS = [
              [ "Today", { :start => "Date.today", :end => "Date.tomorrow" } ],
              [ "Tomorrow", { :start => "Date.tomorrow", :end => "Date.tomorrow + 1.day" } ],
              [ "Yesterday", { :start => "Date.yesterday", :end => "Date.today" } ],
              [ "This week", { :start => "Date.today.at_beginning_of_week", :end => "Date.today.at_end_of_week" } ],
              [ "In the past", { :start => "Time.utc(1000)", :end => "Date.today" } ],
              [ "Last week", { :start => "Date.today.at_beginning_of_week - 7", :end => "Date.today.at_beginning_of_week" } ],
              [ "This month", { :start => "Date.today.at_beginning_of_month", :end => "Date.today.at_end_of_month" } ],
              [ "Last month", { :start => "(Date.today.at_beginning_of_month - 10.days).at_beginning_of_month", :end => "Date.today.at_beginning_of_month" } ],
              [ "This year", { :start => "Date.today.at_beginning_of_year", :end => "Date.today.at_end_of_year" } ],
              [ "Last year", { :start => "(Date.today.at_beginning_of_year - 10.days).at_beginning_of_year", :end => "(Date.today.at_beginning_of_year - 10.days).at_end_of_year" } ]
             ]

  # Updates or creates the default time ranges
  def self.create_defaults
    DEFAULTS.each do |name, attrs|
      TimeRange.find_or_create_by_name(name).update_attributes(attrs)
    end
  end

  def TimeRange.end_time(name)
    eval(RANGES[name][1])
  end
  def TimeRange.start_time(name)
    eval(RANGES[name][0])
  end
private
  RANGES= {
    :'This week'  => ['Time.now.beginning_of_week.utc', 'Time.now.end_of_week.utc'],
    :'Last week'  => ['1.week.ago.beginning_of_week.utc', 'Time.now.beginning_of_week.utc'],
    :'This month' => ['Time.now.beginning_of_month.utc', 'Time.now.end_of_month.utc'],
    :'Last month' => ['1.month.ago.beginning_of_month.utc','Time.now.beginning_of_month.utc'],
    :'This year'  => ['Time.now.beginning_of_year.utc', 'Time.now.end_of_year.utc'],
    :'Last year'  => ['1.year.ago.beginning_of_year.utc', 'Time.now.beginning_of_year.utc']
  }
end

# == Schema Information
#
# Table name: time_ranges
#
#  id         :integer(4)      not null, primary key
#  name       :string(255)
#  start      :text
#  end        :text
#  created_at :datetime
#  updated_at :datetime
#

