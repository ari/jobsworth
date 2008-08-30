require File.dirname(__FILE__) + '/../test_helper'

context "A user" do
  use_controller LoginController
  fixtures :users, :companies, :customers
  
  setup do
    use_controller LoginController
    @request.host = 'cit.local.host'
  end 
  
  specify "is required to log in" do 
    use_controller ActivitiesController
    get :list
    response.should.redirect :controller => 'login', :action => 'login'
  end

  specify "should be able to signup" do
    user_count = User.count
    company_count = Company.count
    customer_count = Customer.count
    
    post :take_signup, { :username => 'newuser', :password => 'newpassword', :password_again => 'newpassword', :name => "New User", :email => "new@clockingit.com", :company => 'New Company',
      :subdomain => 'newsubdomain', :user => {:time_zone => 'Europe/Oslo' } }

    User.count.should.equal user_count + 1
    Company.count.should.equal company_count + 1
    Customer.count.should.equal customer_count + 1

    should.redirect
  end 
  
  specify "should not login without username and password" do
    post :validate, :user => { 'username' => '', 'password' => '' }
    should.redirect_to :controller => 'login', :action => 'login'
  end 

  specify "should be able to log in" do
    post :validate, :user => { 'username' => 'test', 'password' => 'password' }
    should.redirect_to :controller => 'activities', :action => 'list'

    assigns(:user).should.not.be.nil?
    session[:user_id].should.equal users(:admin).id
  end 

end 
