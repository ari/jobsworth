require File.dirname(__FILE__) + '/../test_helper'

class CustomAttributesControllerText < ActionController::TestCase
  fixtures :users, :companies
  
  def setup
    use_controller CustomAttributesController

    @request.with_subdomain('cit')
    @request.session[:user_id] = users(:admin).id
  end
  
  test "/index should render :success" do
    get :index
    status.should.be :success
  end

  test "/edit should render :success" do
    get :index, :type => "User"
    status.should.be :success
  end

end
