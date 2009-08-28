require File.dirname(__FILE__) + '/../test_helper'

class CompaniesControllerTest < ActionController::TestCase
  fixtures :companies, :users

  def setup
    @request.with_subdomain('cit')
    @user = users(:admin)
    @request.session[:user_id] = @user.id
    @user.company.create_default_statuses
  end
  
  test "/edit should render :success" do
    get :edit, :id => @user.company.id
    assert_response :success
  end

end
