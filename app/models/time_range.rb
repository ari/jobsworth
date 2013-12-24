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
              [ I18n.t('time.today'), { :start => "Date.today", :end => "Date.tomorrow" } ],
              [ I18n.t('time.tomorrow'), { :start => "Date.tomorrow", :end => "Date.tomorrow + 1.day" } ],
              [ I18n.t('time.yesterday'), { :start => "Date.yesterday", :end => "Date.today" } ],
              [ I18n.t('time.this_week'), { :start => "Date.today.at_beginning_of_week", :end => "Date.today.at_end_of_week" } ],
              [ I18n.t('time.in_the_past'), { :start => "Time.utc(1000)", :end => "Date.today" } ],
              [ I18n.t('time.in_the_future'), { :start => "Date.tomorrow", :end => "TIme.utc(2100)" } ],
              [ I18n.t('time.last_week'), { :start => "Date.today.at_beginning_of_week - 7", :end => "Date.today.at_beginning_of_week" } ],
              [ I18n.t('time.this_month'), { :start => "Date.today.at_beginning_of_month", :end => "Date.today.at_end_of_month" } ],
              [ I18n.t('time.last_month'), { :start => "(Date.today.at_beginning_of_month - 10.days).at_beginning_of_month", :end => "Date.today.at_beginning_of_month" } ],
              [ I18n.t('time.this_year'), { :start => "Date.today.at_beginning_of_year", :end => "Date.today.at_end_of_year" } ],
              [ I18n.t('time.last_year'), { :start => "(Date.today.at_beginning_of_year - 10.days).at_beginning_of_year", :end => "(Date.today.at_beginning_of_year - 10.days).at_end_of_year" } ],
              [ I18n.t('time.yesterday_or_earlier'), { :start => "Time.utc(1000)", :end => "Date.yesterday" } ],
              [ I18n.t('time.yesterday_or_later'), { :start => "Date.yesterday", :end => "Time.utc(2100)" } ],
              [ I18n.t('time.tomorrow_or_earlier'), { :start => "Time.utc(1000)", :end => "Date.tomorrow" } ],
              [ I18n.t('time.tomorrow_or_later'), { :start => "Date.tomorrow", :end => "Time.utc(2100)" } ],
              [ I18n.t('time.today_or_later'), { :start => "Date.today", :end => "Time.utc(2100)" } ],
              [ I18n.t('time.today_or_earlier'), { :start => "Time.utc(1000)", :end => "Date.today" } ]
             ]

  FUTURE_KEYWORDS_LIST = [I18n.t('time.today_or_later'),I18n.t('time.tomorrow_or_later'),
                          I18n.t('time.yesterday_or_later'),I18n.t('time.in_the_future'),
                          I18n.t('time.yesterday_or_later'), I18n.t('time.tomorrow'),
                          I18n.t('time.tomorrow_or_earlier')]
  
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

  def self.keyword_in_future? (keyword)
    FUTURE_KEYWORDS_LIST.each do |name|
      if (name == keyword.to_s)
        return true
      end
    end
    return false
  end

private
  RANGES= {
    I18n.t('time_key_words.today')  => ['Time.now.beginning_of_day.utc', 'Time.now.end_of_day.utc'],
    I18n.t('time_key_words.yesterday') => ['Time.now.yesterday.beginning_of_day.utc','Time.now.yesterday.end_of_day'],
    I18n.t('time_key_words.tomorrow')   => ['Time.now.tomorrow.beginning_of_day.utc','Time.now.tomorrow.end_of_day.utc'],
    I18n.t('time_key_words.this_week')  => ['Time.now.beginning_of_week.utc', 'Time.now.end_of_week.utc'],
    I18n.t('time_key_words.last_week')  => ['1.week.ago.beginning_of_week.utc', 'Time.now.beginning_of_week.utc'],
    I18n.t('time_key_words.this_month') => ['Time.now.beginning_of_month.utc', 'Time.now.end_of_month.utc'],
    I18n.t('time_key_words.last_month') => ['1.month.ago.beginning_of_month.utc','Time.now.beginning_of_month.utc'],
    I18n.t('time_key_words.this_year')  => ['Time.now.beginning_of_year.utc', 'Time.now.end_of_year.utc'],
    I18n.t('time_key_words.last_year')  => ['1.year.ago.beginning_of_year.utc', 'Time.now.beginning_of_year.utc'],
    I18n.t('time_key_words.in_the_past')=> ['Time.utc(1000)', 'Time.now.beginning_of_day.utc'],
    I18n.t('time_key_words.in_the_future') => ['Time.now.tomorrow.beginning_of_day.utc','Time.utc(2100)'],
    I18n.t('time_key_words.yesterday_or_earlier')=> ['Time.utc(1000)', 'Time.yesterday.end_of_day.utc'],
    I18n.t('time_key_words.yesterday_or_later') => ['Time.now.yesterday.beginning_of_day.utc','Time.utc(2100)'],
    I18n.t('time_key_words.tomorrow_or_earlier') =>['Time.utc(1000)', 'Time.tomorrow.end_of_day.utc'],
    I18n.t('time_key_words.tomorrow_or_later') => ['Time.now.tomorrow.beginning_of_day.utc','Time.utc(2100)'],
    I18n.t('time_key_words.today_or_earlier')=> ['Time.utc(1000)', 'Time.now.end_of_day.utc'],
    I18n.t('time_key_words.today_or_later') => ['Time.now.beginning_of_day.utc','Time.utc(2100)'],
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

