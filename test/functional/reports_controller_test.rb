require File.dirname(__FILE__) + '/../test_helper'

class ReportsControllerTest < ActionController::TestCase
  fixtures :users, :companies, :tasks
  
  def setup
    @request.with_subdomain('cit')
    @user = users(:admin)
    @request.session[:user_id] = @user.id
  end

  test "list should render" do
    get :list
    assert_response :success
  end
end
