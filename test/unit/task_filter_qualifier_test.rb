require 'test_helper'

class TaskFilterQualifierTest < ActiveSupport::TestCase
  should_belong_to :task_filter
  should_belong_to :qualifiable

  should_validate_presence_of :qualifiable

  context "a task with a different task num than id" do
    setup do
      @user = User.make

      @task = Task.make(:company => @user.company)
      @task.task_num = @task.id + 1
      @task.users << @user
      @task.save!

      assert @user.can_view_task?(@task)
      assert @task.reload.id != @task.task_num

      filter = TaskFilter.make_unsaved(:user_id => @user.id)
      @qualifier = filter.qualifiers.build(:task_filter => filter)
      assert_nil @qualifier.qualifiable
    end

    should "set task from task_num if use can view task" do
      @qualifier.task_num = @task.task_num
      @qualifier.save!
      assert_equal @task, @qualifier.qualifiable
    end

  end

end
