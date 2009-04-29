require 'test_helper'

class UsersControllerText < ActionController::TestCase
  fixtures(:users)
  
  def setup
    use_controller UsersController

    @request.with_subdomain('cit')
    @user = users(:admin)
    @request.session[:user_id] = @user.id
  end
  

  test "/edit should render :success" do
    get :edit, :id => @user.id

    status.should.be :success
  end

  test "/update should redirect to /clients/edit" do
    post(:update, :id => @user.id, :user => { :name => "test" })

    assert_redirected_to :controller => "clients", :action => "edit"
  end
end
