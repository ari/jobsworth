require File.dirname(__FILE__) + '/../test_helper'

context "ApplicationController" do 
  fixtures :users, :companies, :customers, :tasks, :projects, :milestones, :work_logs
  
  setup do
     use_controller ActivitiesController

     @request.with_subdomain('cit')
     @request.session[:user_id] = users(:admin).id
  end

  specify "should get current_user" do
     get :index
     @controller.current_user.should.equal(users(:admin))
  end

  specify "user 1 should be admin" do
     get :index
     assigns(:current_user).admin?.should.be true
  end

  specify "user 2 should NOT be admin" do
     @request.session[:user_id] = users(:fudge).id
     get :index
     assigns(:current_user).admin?.should.be false
  end

  specify "should get all online users" do
     get :index
     @controller.current_users.size.should.be 2
  end

  specify "parse_time should handle 1w2d3h4m" do
     get :index
     @controller.parse_time("1w2d3h4m").should.be(200040)
     @controller.parse_time("4m").should.be(240)
     @controller.parse_time("1d").should.be(27000)
  end


  
end
