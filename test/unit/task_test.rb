require File.dirname(__FILE__) + '/../test_helper'

class TaskTest < Test::Unit::TestCase
  fixtures :tasks, :projects, :users, :companies, :customers

  def setup
    @task = tasks(:normal_task)
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

  def test_after_save
    # TODO
  end

  def test_next_repeat_date
    # TODO
  end

  def test_repeat_summary
    # TODO
  end

  def test_ready?
    # TODO
  end

  def test_active?
    @task.hide_until = nil
    assert @task.active?

    @task.hide_until = Time.now.utc - 1.hour
    assert @task.active?

    @task.hide_until = Time.now.utc + 1.hour
    assert !@task.active?
  end

  def test_worked_on?
     assert !@task.worked_on?

     sheet = @task.sheets.build(:project => projects(:test_project), :user => users(:admin) )
     sheet.save

     assert @task.worked_on?
  end

  def test_set_task_num
    max = Task.maximum('task_num', :conditions => ["company_id = ?", @task.company.id])
    @task.set_task_num(@task.company.id)
    assert_equal max + 1, @task.task_num
  end

  def test_time_left
    assert_equal 0, @task.time_left

    @task.due_at = Time.now.utc + 1.day
    assert 86390 < @task.time_left.to_i
  end

  def test_overdue?
    @task.due_at = nil
    assert_equal false, @task.overdue?

    @task.due_at = Time.now.utc + 1.day
    assert_equal false, @task.overdue?

    @task.due_at = Time.now.utc - 1.day
    assert_equal true, @task.overdue?
  end

  def test_worked_minutes
    # TODO
  end

  def test_full_name
    # TODO
  end

  def test_full_tags
    # TODO
  end

  def test_full_name_without_links
    # TODO
  end

  def test_full_tags_without_links
    # TODO
  end

  def test_issue_name
    assert_equal "[#1] Test", @task.issue_name
  end

  def test_issue_num
    assert_equal "#1", @task.issue_num

    @task.status = 2
    assert_equal "<strike>#1</strike>", @task.issue_num
  end

  def test_status_name
    assert_equal "#1 Test", @task.status_name

    @task.status = 2
    assert_equal "<strike>#1</strike> Test", @task.status_name
  end

end
