require 'test_helper'

class TimeRangeTest < ActiveSupport::TestCase
  def setup
    @time_range = TimeRange.make
  end
  subject { @time_range }
  
  should_validate_presence_of :name
  should_validate_uniqueness_of :name

  context "a normal time range" do
    should "eval start to get start_time" do
      @time_range.start = "Date.today"
      assert_equal Date.today, @time_range.start_time
    end

    should "eval end to get end_time" do
      @time_range.end = "Date.tomorrow"
      assert_equal Date.tomorrow, @time_range.end_time
    end
  end
end
