require "test_helper"

class TimeParserTest < ActiveSupport::TestCase
  setup do
    @user = User.make(:days_per_week => 5, :workday_duration => 480)
  end

  #   def self.format_duration(minutes, duration_format, day_duration, days_per_week = 5)
  context "format duration" do
    should "be able to format weeks" do
      assert_equal "1w 2d 3h 4m", TimeParser.format_duration(3544, 0, 480, 5)
    end

    should "be able to format days" do
      assert_equal "1d", TimeParser.format_duration(480, 0, 480, 5)
    end

    should "be able to format hours" do
      assert_equal "2h", TimeParser.format_duration(120, 0, 480, 5)
    end

    should "be able to format minutes" do
      assert_equal "4m", TimeParser.format_duration(4, 0, 480, 5)
    end
  end

  context "parse time" do
    should "be able to parse week, day, hour and minutes" do
     assert_equal 3544, TimeParser.parse_time(@user, "1w2d3h4m")
    end

    should "be able to parse days" do
     assert_equal 480, TimeParser.parse_time(@user, "1d")
    end

    should "be able to parse hours" do
     assert_equal 180, TimeParser.parse_time(@user, "3h")
    end

    should "be able to parse minutes" do
     assert_equal 4, TimeParser.parse_time(@user, "4m")
    end
  end
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

