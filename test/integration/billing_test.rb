require 'test_helper'

class BillingTest < ActionDispatch::IntegrationTest
  context "a logged in user" do
    setup do
      @user= login
      @user.option_tracktime= true
      @user.admin= true
      @user.save!
    end
    context "with some existing tasks" do
      setup do
        @project= project_with_some_tasks(@user)
        visit "/"
        @task= @project.tasks.first
        visit ('/tasks/edit/'+@task.task_num.to_s)
        fill_in "comment", :with => "my new comment"
        find("#taskform #work_log_duration").set("5m")
      end
      context "when select Time Range- Last Year in report" do
        should "be in the report's table link to the task, on which work" do
          find("#taskform #work_log_started_at").set((@user.tz.now - 1.year).strftime(@user.date_format+' '+@user.time_format))
          click_button('Save')
          click_link('Billing')
          select('Last Year', :from => 'report_range')
          click_button('Run Report')
          link= find(:css,'.row_heading a')
          assert_equal @task.name, link.text
        end
      end
      context "select Time Range- Last Month in report" do
        should "be in the report's table link to the task, on which work" do
          find("#taskform #work_log_started_at").set((@user.tz.now - 1.month).strftime(@user.date_format+' '+@user.time_format))
          click_button('Save')
          click_link('Billing')
          select('Last Month', :from => 'report_range')
          click_button('Run Report')
          link= find(:css, '.row_heading a')
          assert_equal @task.name, link.text
        end
      end
    end
  end
end
