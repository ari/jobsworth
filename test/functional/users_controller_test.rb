require 'test_helper'

class UsersControllerTest < ActionController::TestCase
  fixtures(:users)
  
  def setup
    @request.with_subdomain('cit')
    @user = users(:admin)
    @request.session[:user_id] = @user.id
  end
  

  test "/edit should render :success" do
    get :edit, :id => @user.id
    assert_response :success
  end

  test "/update should redirect to /clients/edit" do
    post(:update, :id => @user.id, :user => { :name => "test" })

    assert_redirected_to :controller => "clients", :action => "edit"
  end
end
