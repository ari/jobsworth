require File.dirname(__FILE__) + '/../test_helper'

class IcalEntryTest < ActiveRecord::TestCase
  fixtures :ical_entries

  # Replace this with your real tests.
  def test_truth
    assert true
  end
end

# == Schema Information
#
# Table name: ical_entries
#
#  id          :integer(4)      not null, primary key
#  task_id     :integer(4)
#  work_log_id :integer(4)
#  body        :text
#

