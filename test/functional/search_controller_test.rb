require 'test_helper'

context "SearchController" do
  fixtures(:users)
  
  setup do
    use_controller SearchController

    @request.with_subdomain('cit')
    @user = users(:admin)
    @request.session[:user_id] = @user.id
  end
  

  specify "/search should include clients" do
    @user.company.customers.new(:name => "testclient").save!

    get :search, :query => "testclient"

    found = assigns["customers"]
    found.each { |c| puts c.name }
    assert_equal 1, found.length

    status.should.be :success
  end
end
