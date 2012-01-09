require 'test_helper'

class TypeValidationTest < ActionController::IntegrationTest
  context "A logged in user with existings projects" do
    setup do
      @user = login
      @project = project_with_some_tasks(@user)
      @milestone =  Milestone.make(:project => @project, :user => @user,
                                   :company => @project.company)
    end
    context "when the Type property is mandatory and task's Type is not selected" do
        setup do
          type= @user.company.properties.where("name=?","Type").first
          type.mandatory= true
          type.save!
        end
        context "creating a new task" do
          setup do
            visit "/"
            click_link "New Task"
            fill_in "task_name", :with => "a brand new task"
            fill_in "task_description", :with => "a new desc"
            select @project.name, :from => "Project"
            select @milestone.name, :from => "Milestone"
          end
          should "be validation message: Type is required, and task should not be created" do
            @task_count= Task.count
            select "", :from => "Type"
            click_button "Save"
            task_count2= Task.count
            assert_equal @task_count, task_count2
            assert page.has_content?("Type is required")
          end
        end
        context "when edit task" do
          setup do
            @task= @project.tasks.first
            visit('/tasks/edit/'+@task.task_num.to_s)
          end
          should "be validation message: Type is required, and task sould not be saved" do
            fill_in "task_description", :with => "Should not be saved descr"
            select "", :from => "Type"
            click_button "Save"
            @task.reload
            assert page.has_content?("Type is required")
            assert_not_equal "Should not be saved descr", @task.description
          end
        end
      end
  end
end
