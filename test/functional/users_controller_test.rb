require 'test_helper'

context "UsersController" do
  fixtures(:users)
  
  setup do
    use_controller UsersController

    @request.with_subdomain('cit')
    @user = users(:admin)
    @request.session[:user_id] = @user.id
  end
  

  specify "/edit should render :success" do
    get :edit, :id => @user.id

    status.should.be :success
  end

  specify "/update should redirect to /customers/list" do
    post(:update, :id => @user.id, :user => { :name => "test" })

    assert_redirected_to :controller => "customers", :action => "list"
  end
end
