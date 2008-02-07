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
  
  def test_done?
    task = Task.new
    task.status = 0
    task.completed_at = nil
    assert_not_equal true, task.done?

    task.status = 2
    assert_not_equal true, task.done?

    task.status = 1
    assert_not_equal true, task.done?

    task.status = 0
    task.completed_at = Time.now.utc
    assert_not_equal true, task.done?

    task.status = 2
    task.completed_at = Time.now.utc
    assert_equal true, task.done?
  end
  
  def test_parse_repeat
    task = Task.new
    assert_equal "a:1", task.parse_repeat('every day')
    assert_equal "w:1", task.parse_repeat('every monday')
    assert_equal "n:2:1", task.parse_repeat('every 2nd monday')
    assert_equal "a:7", task.parse_repeat('every 7 days')
    assert_equal "a:14", task.parse_repeat('every 14 days')
    assert_equal "l:5", task.parse_repeat('every last friday')
    assert_equal "m:15", task.parse_repeat('every 15th')
  end
  
end
