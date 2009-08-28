require 'test_helper'

class NewTaskTest < ActionController::IntegrationTest
  context "A logged in user with existings projects" do
    setup do
      @user = login
      @project = project_with_some_tasks(@user)
      @milestone =  Milestone.make(:project => @project, :user => @user,
                                   :company => @project.company)
    end

    context "creating a new task" do
      setup do
        visit "/"
        click_link "new task"

        fill_in "title", :with => "a brand new task"
        fill_in "description", :with => "a new desc"
        select @project.name, :from => "project"
        select @milestone.name, :from => "milestone"
      end

      should "be able to create task ok" do
        project_count = @project.tasks.count
        milestone_count = @milestone.tasks.count
        
        click_button "create"
        
        assert_equal project_count + 1, @project.tasks.count
        assert_equal milestone_count + 1, @milestone.tasks.count
      end

      should "be able to create a worklog using the task description" do
        fill_in "work_log_duration", :with => "5m"
        click_button "create"
        
        task = @user.company.tasks.last
        log = task.reload.work_logs.detect { |wl| wl.duration == 300 }
        assert_not_nil log
        assert_equal task.description, log.body
      end
    end
  end
end
