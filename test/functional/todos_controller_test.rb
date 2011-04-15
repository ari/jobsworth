require 'test_helper'

class TodosControllerTest < ActionController::TestCase
  signed_in_admin_context do
    setup do
      @task = Task.make(:company => @user.company)
      @task.users << @user
      @task.save!
      @user.projects<< @task.project
      assert @user.can_view_task?(@task)

      assert @task.todos.empty?
    end

    should "be able to create todos" do
      post(:create, :task_id => @task.id,
           :todo => { :name => "test todo" })

      @task = @task.reload
      assert_equal 1, @task.todos.length
      assert_equal "test todo", @task.todos[0].name

      assert_response :success
    end

    context "with an existing todo" do
      setup do
        @todo = @task.todos.build(:name => "test todo")
        @todo.save!
      end

      should "be able to edit todos" do
        post(:update, :task_id => @task.id, :id => @todo.id,
             :todo => { :name => "new name" })

        assert_equal "new name", @todo.reload.name
        assert_response :success
      end

      should "be able to close todos" do
        assert_nil @todo.completed_at
        post(:toggle_done, :task_id => @task.id, :id => @todo.id)

        @todo = @todo.reload
        assert_not_nil @todo.completed_at
        assert_equal @user, @todo.completed_by_user

        assert_response :success
      end

      should "be able to delete todos" do
        delete(:destroy, :task_id => @task.id, :id => @todo.id)

        assert_nil Todo.find_by_id(@todo.id)
        assert_response :success
      end
    end

  end
end
