require 'test_helper'

class WorkControllerTest < ActionController::TestCase
  context "A logged in user" do
    setup do
      @user = login
      
      project = project_with_some_tasks(@user)
      @task = project.tasks.first
      assert @user.can_view_task?(@task)
    end

    should "render start" do
      get :start, :task_num => @task.task_num
      
      sheet = assigns("current_sheet")
      assert_equal @task, sheet.task
      assert_equal @user, sheet.user
      assert_redirected_to "/activities/list"
    end

    context "with a current sheet" do
      setup do
        @sheet = Sheet.new(:user => @user, :task => @task, 
                           :project => @task.project)
        @sheet.created_at = 30.minutes.ago
        @sheet.save!
      end 
      
      should "render stop" do
        get :stop
        assert @user.sheets.empty?

        redir = @response.redirected_to
        assert redir.index("/work_logs/new?")
      end

      should "render cancel" do
        get :cancel
        assert_redirected_to "/activities/list"
        assert @user.sheets.empty?
      end

      should "toggle sheet paused on pause" do
        get :pause
        assert @sheet.reload.paused?

        get :pause
        assert !@sheet.reload.paused?
      end
    end
  end
end
