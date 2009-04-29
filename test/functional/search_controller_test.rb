require 'test_helper'

class SearchControllerText < ActionController::TestCase
  fixtures(:users)
  
  def setup
    use_controller SearchController

    @request.with_subdomain('cit')
    @user = users(:admin)
    @request.session[:user_id] = @user.id
  end
  

  test "/search should include clients" do
    @user.company.customers.new(:name => "testclient").save!

    get :search, :query => "testclient"

    found = assigns["customers"]
    assert_equal 1, found.length

    status.should.be :success
  end
end
