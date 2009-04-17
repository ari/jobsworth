require File.dirname(__FILE__) + '/../test_helper'

context "Resources" do
  fixtures :companies, :users

  setup do
    use_controller ResourcesController
    @request.with_subdomain("cit")
    user = users(:admin)
    user.use_resources = true
    user.save!
    @request.session[:user_id] = user.id

    company = user.company
    @type = company.resource_types.build(:name => "test")
    @type.new_type_attributes = [ { :name => "a1" }, { :name => "a2" } ]
    @type.save!

    customer = company.customers.build(:name => "test cust")
    customer.save!

    @resource = company.resources.build(:name => "test res")
    @resource.resource_type = @type
    @resource.customer = customer
  end

  specify "all should redirect if not use_resources set on user" do
    user = User.find(@request.session[:user_id])
    user.use_resources = false
    user.save!

    end_page = { :controller => "activities", :action => "list" }

    get :new
    assert_redirected_to(end_page)

    get :edit, @resource.id
    assert_redirected_to(end_page)

    post :create, @resource.id
    assert_redirected_to(end_page)

    post :update, @resource.id
    assert_redirected_to(end_page)

    post :destroy, @resource.id
    assert_redirected_to(end_page)
  end 

  specify "/new should render :success" do
    get :new
    status.should.be :success
  end

  specify "/edit should render :success" do
    assert @resource.save
    get :edit, :id => @resource.id

    status.should.be :success
  end

  specify "/index should render :success" do
    assert @resource.save

    get :index
    status.should.be :success

    resources = assigns["resources"]
    assert resources.length > 0
  end
end
