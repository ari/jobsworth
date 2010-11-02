require "test_helper"

class LoginControllerTest < ActionController::TestCase
  fixtures :users, :companies, :customers
  
  def setup
    @request.host = 'cit.local.host'
  end 
  
#   test "is required to log in" do 
#     use_controller ActivitiesController
#     get :list
#     response.should.redirect :controller => 'login', :action => 'login'
#   end
  
  test "should not login without username and password" do
    post :validate, :user => { 'username' => '', 'password' => '' }
    assert_redirected_to :controller => 'login', :action => 'login'
  end 

  test "should be able to log in" do
    post :validate, :user => { 'username' => 'test', 'password' => 'password' }
    assert_redirected_to :controller => 'activities', :action => 'list'

    assert_not_nil assigns(:user)
    assert_equal users(:admin).id, session[:user_id]
  end 

end 
