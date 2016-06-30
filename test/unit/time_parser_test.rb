require 'test_helper'

class TimeParserTest < ActiveSupport::TestCase
  #   def self.format_duration(minutes)
  context 'format duration' do
    should 'be able to format weeks' do
      assert_equal '2w', TimeParser.format_duration(20160)
    end

    should 'be able to format days' do
      assert_equal '2d', TimeParser.format_duration(2880)
    end

    should 'be able to format hours' do
      assert_equal '2h', TimeParser.format_duration(120)
    end

    should 'be able to format minutes' do
      assert_equal '4m', TimeParser.format_duration(4)
    end

    should 'be able to format weeks and days' do
      assert_equal '2w 2d', TimeParser.format_duration(23040)
    end

    should 'be able to format days and hours' do
      assert_equal '2d 2h', TimeParser.format_duration(3000)
    end

    should 'be able to format hours and minutes' do
      assert_equal '2h 10m', TimeParser.format_duration(130)
    end
  end

  context 'parse time' do
    should 'be able to parse hours and minutes' do
      assert_equal 184, TimeParser.parse_time('3h4m')
    end

    should 'be able to parse hours' do
      assert_equal 180, TimeParser.parse_time('3h')
    end

    should 'be able to parse minutes' do
      assert_equal 4, TimeParser.parse_time('4m')
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
