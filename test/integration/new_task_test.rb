require 'test_helper'

class NewTaskTest < ActionController::IntegrationTest
  context "A logged in user with existings projects" do
    setup do
      @user = login
      @project = project_with_some_tasks(@user)
      @milestone =  Milestone.make(:project => @project, :user => @user,
                                   :company => @project.company)
    end

    should "be able create a new task" do
      project_count = @project.tasks.count
      milestone_count = @milestone.tasks.count

      visit "/"
      click_link "new task"
      fill_in "summary", :with => "a brand new task"
      fill_in "description", :with => "a new desc"
      select @project.name, :from => "project"
      select @milestone.name, :from => "milestone"
      click_button "create"
      
      assert_equal project_count + 1, @project.tasks.count
      assert_equal milestone_count + 1, @milestone.tasks.count
    end
  end
end
