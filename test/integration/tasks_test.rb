require 'test_helper'

class TasksTest < ActionController::IntegrationTest
  context "A logged in user" do
    setup do
      @user = login
    end

    context "with some existing tasks" do
      setup do
        @project = project_with_some_tasks(@user)
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

        should "be able to set a project"
        should "be able to set a milestone"
        should "be able to set the status"
        should "be able to add comments"
      end
    end
  end
end
