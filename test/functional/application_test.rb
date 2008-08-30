require File.dirname(__FILE__) + '/../test_helper'

context "ApplicationController" do 
  fixtures :users, :companies, :customers, :tasks, :projects, :milestones, :work_logs
  
  setup do
     use_controller ActivitiesController

     @request.with_subdomain('cit')
     @request.session[:user_id] = 1
  end
  
  specify "parse_time should handle 1w2d3h4m" do
     get :index
     @controller.parse_time("1w2d3h4m").should.be(200040)
     @controller.parse_time("4m").should.be(240)
     @controller.parse_time("1d").should.be(27000)
  end
  
end
