require File.dirname(__FILE__) + '/../test_helper'

class CustomAttributesControllerTest < ActionController::TestCase
  fixtures :users, :companies
  
  def setup
    @request.with_subdomain('cit')
    @request.session[:user_id] = users(:admin).id
  end
  
  test "/index should render :success" do
    get :index
    assert_response :success
  end

  test "/edit should render :success" do
    get :index, :type => "User"
    assert_response :success
  end

end
