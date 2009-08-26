require File.dirname(__FILE__) + '/../test_helper'

class CustomAttributesControllerTest < ActionController::TestCase
  fixtures :users, :companies
  
  def setup
    login
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
