require File.dirname(__FILE__) + '/../test_helper'

class WorkLogTest < Test::Unit::TestCase
  fixtures :work_logs

  def setup
    @work_log = WorkLog.find(1)
  end

  # Replace this with your real tests.
  def test_truth
    assert_kind_of WorkLog,  @work_log
  end
end
