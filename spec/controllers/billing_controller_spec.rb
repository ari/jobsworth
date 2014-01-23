require 'spec_helper'

describe BillingController do
  ROWS = [ 1, 2, 3, 4, 5, 6, 7, 8, 9, 20, "property_1", "property_2", "property_3" ]
    
  before :each do
    sign_in_admin
  end
  
  it "Should generate report for pivot by date" do
    projects = FactoryGirl.create_list( :project, 20, :company_id => @logged_user.company.id)
    projects.each do |project|
      task = FactoryGirl.create( :task_record,
                                 :company_id => @logged_user.company.id,
                                 :project_id => project.id )
      
      FactoryGirl.create( :project_permission,
                          :user_id => @logged_user.id,
                          :company_id => @logged_user.company.id,
                          :project_id => project.id )
      
      FactoryGirl.create( :work_log,
                          :task_id => task.id,
                          :duration => 40,
                          :user_id => @logged_user.id,
                          :company_id => @logged_user.company.id,
                          :project_id => project.id )      
    end
    
    ROWS.each do |r|
      get :index, { "report"=> { "type" => "1", "rows" => r, "columns" => "9", "filter_project" => "0", "filter_user" => "0", "worklog_type" => "0", "range" => "7", "start_date" => "11/11/2013", "stop_date" => "24/01/2014", "hide_approved" => "0", "hide_rejected" => "0"}}  
      assigns(:generated_report).should_not be_nil
      response.should render_template(:layout => "basic")
    end
  end
end