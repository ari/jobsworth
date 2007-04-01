require File.dirname(__FILE__) + '/../test_helper'

class TaskTest < Test::Unit::TestCase
  fixtures :tasks

  def setup
    @task = Task.find(1)
  end

  # Replace this with your real tests.
  def test_truth
    assert_kind_of Task,  @task
  end
end
