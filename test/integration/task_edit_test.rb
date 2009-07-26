require 'test_helper'

class TaskEditTest < ActionController::IntegrationTest
  context "A logged in user" do
    setup do
      @user = login
    end

    context "with some existing tasks" do
      setup do
        @project = project_with_some_tasks(@user)
        @project2 = project_with_some_tasks(@user)

        2.times { Milestone.make(:project => @project, :user => @user,
                                 :company => @project.company) }
      end

      context "on the task edit screen" do
        setup do 
          @task = @project.tasks.first
          visit "/"
          click_link "browse"
          click_link @task.name
        end

        should "be able to edit information" do
          fill_in "summary", :with => "a new summary"
          fill_in "tags", :with => "t1, t2"
          fill_in "description", :with => "a new description"
          
          click_button "save"
          
          @task.reload
          assert_equal "a new summary", @task.name
          assert_equal "a new description", @task.description
          assert_equal "T1 / T2", @task.full_tags_without_links
        end

        should "be able to set a project" do
          assert_equal @project, @task.project

          select @project2.name, :from => "project"
          click_button "save"
          
          @task.reload
          assert_equal @project2, @task.project
        end

        should "be able to set a milestone" do
          assert_nil @task.milestone

          select @project.milestones.last.name, :from => "milestone"
          click_button "save"
          
          @task.reload
          assert_equal @project.milestones.last, @task.milestone
        end

        should "be able to set the status" do
          select "Set in Progress", :from => "status"
          click_button "save"

          @task.reload
          assert_equal "In Progress", @task.status_type
        end

        should "be able to add comments" do
          assert @task.work_logs.empty?

          fill_in "comment", :with => "a new comment"
          click_button "save"

          @task.reload
          assert_not_nil @task.work_logs.first.body.index("a new comment")
        end
      end
    end
  end
end
