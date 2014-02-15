require 'spec_helper'

describe BillingController do
    
  context "Pivot by date or days of week" do
    
    ROWS = [ 1, 2, 3, 4, 5, 6, 7, 8, 9, 20, "property_1", "property_2", "property_3" ]
    before :each do
      sign_in_admin(:id => 1)
    end
  
	it "Should generate report for pivot by date" do
	  FactoryGirl.create( :property, :company_id => @logged_user.company.id, :name => "Type")
	  FactoryGirl.create( :property, :company_id => @logged_user.company.id, :name => "Priority")
	  FactoryGirl.create( :property, :company_id => @logged_user.company.id, :name => "Severity")
	  projects = FactoryGirl.create_list( :project, 20, :company_id => @logged_user.company.id)	  
	  days = 30
      projects.each do |project|
        task = FactoryGirl.create( :task_record,
                                   :company_id => @logged_user.company.id,
                                   :project_id => project.id )
      
	    FactoryGirl.create( :project_permission,
                            :user_id => @logged_user.id,
                            :company_id => @logged_user.company.id,
                            :project_id => project.id )
      
	    FactoryGirl.create( :work_log,
							:started_at => DateTime.now - days,
                            :task_id => task.id,
                            :duration => 40,
                            :user_id => @logged_user.id,
                            :company_id => @logged_user.company.id,
                            :project_id => project.id )
		days -= 1
      end
	  ROWS.each do |r|
	    get :index, :report => { "type" => "1",
							     "rows" => r,
							     "columns" => "9",
							     "filter_project" => "0",
							     "filter_user" => "0",
							     "worklog_type" => "0",
							     "range" => "7",
							     "start_date" => "11/11/2013",
							     "stop_date" => "24/01/2100",
							     "hide_approved" => "0",
							     "hide_rejected" => "0" }  
        assigns(:title).should_not be_nil
        assigns(:generated_report).should_not be_nil
        response.should render_template(:layout => "basic")
      end
    end
  
    it "should arrange column headers in ascending order" do
	  COLUMNS = [ "7", "9" ]
	  COLUMNS.each do |c|
	    ROWS.each do |r|
	      get :index, :report => { "type" => "1",
							       "rows" => r,
							       "columns" => c,
							       "filter_project" => "0",
							       "filter_user" => "0",
							       "worklog_type" => "0",
							       "range" => "7",
							       "start_date" => "11/11/2013",
							       "stop_date" => "24/01/2100",
							       "hide_approved" => "0",
							       "hide_rejected" => "0" }
		  column_headers = assigns(:column_headers)
		  column_headers.delete(:__)
		  column_headers.keys.should == column_headers.keys.sort
	    end
	  end
    end
  end
end
