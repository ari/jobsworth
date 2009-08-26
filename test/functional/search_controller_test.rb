require 'test_helper'

class SearchControllerTest < ActionController::TestCase
  fixtures(:users)
  
  def setup
    @request.with_subdomain('cit')
    @user = users(:admin)
    @request.session[:user_id] = @user.id
    @user.company.create_default_statuses
  end
  

  test "/search should include clients" do
    @user.company.customers.new(:name => "testclient").save!

    get :search, :query => "testclient"

    found = assigns["customers"]
    assert_equal 1, found.length
    assert_response :success
  end

  test "/search should render with no query" do
    get :search, :query => ""
    assert_response :success
  end
end
