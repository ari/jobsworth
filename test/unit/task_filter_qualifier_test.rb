require "test_helper"

class TaskFilterQualifierTest < ActiveSupport::TestCase
  should belong_to(:task_filter)
  should belong_to(:qualifiable)

  should validate_presence_of(:qualifiable)

  context "a task with a different task num than id" do
    setup do
      @user = User.make

      @task = Task.make(:company => @user.company)
      @task.task_num = @task.id + 1
      @task.users << @user
      @task.save!
      @user.projects<< @task.project
      assert @user.can_view_task?(@task)
      assert @task.reload.id != @task.task_num

      filter = TaskFilter.make_unsaved(:user_id => @user.id)
      @qualifier = filter.qualifiers.build(:task_filter => filter)
      assert_nil @qualifier.qualifiable
    end

    should "set task from task_num if user can view task" do
      @qualifier.task_num = @task.task_num
#      @qualifier.save!
      @qualifier.valid?
      assert_equal @task, @qualifier.qualifiable
    end

  end

end






# == Schema Information
#
# Table name: task_filter_qualifiers
#
#  id                 :integer(4)      not null, primary key
#  task_filter_id     :integer(4)
#  qualifiable_type   :string(255)
#  qualifiable_id     :integer(4)
#  created_at         :datetime
#  updated_at         :datetime
#  qualifiable_column :string(255)
#  reversed           :boolean(1)      default(FALSE)
#
# Indexes
#
#  fk_task_filter_qualifiers_task_filter_id  (task_filter_id)
#

