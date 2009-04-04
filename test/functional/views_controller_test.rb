require File.dirname(__FILE__) + '/../test_helper'

context "Views" do
  fixtures :users, :companies, :tasks
  
  setup do
    use_controller ViewsController

    @request.with_subdomain('cit')
    @request.session[:user_id] = users(:admin).id
  end
  
  specify "/new should render :success" do
    get :new
    status.should.be :success
  end

end
