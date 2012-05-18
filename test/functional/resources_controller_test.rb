require "test_helper"

class ResourcesControllerTest < ActionController::TestCase
  fixtures :companies, :users

  def setup
    @user = users(:admin)
    sign_in @user
    @request.session[:user_id] = session["warden.user.user.key"][1].first
    @user.company.create_default_statuses
    @user.use_resources = true
    @user.save!

    company = @user.company
    @type = company.resource_types.build(:name => "test")
    @type.new_type_attributes = [ { :name => "a1" }, { :name => "a2" } ]
    @type.save!

    @customer = company.customers.build(:name => "test cust")
    @customer.save!

    @resource = company.resources.build(:name => "test res")
    @resource.resource_type = @type
    @resource.customer = @customer
    @resource.save!
  end

  test "all should redirect if not use_resources set on user" do
    user = User.find(@request.session[:user_id])
    user.use_resources = false
    user.save!

    end_page = root_path

    get :new
    assert_redirected_to(end_page)

    get :edit, :id => @resource.id
    assert_redirected_to(end_page)

    post :create
    assert_redirected_to(end_page)

    post :update, :id => @resource.id
    assert_redirected_to(end_page)

    post :destroy, :id => @resource.id
    assert_redirected_to(end_page)
  end 

  test "should not redirect if use_resources set on user" do
    user = User.find(@request.session[:user_id])
    user.use_resources = true
    user.save!

    get :edit, :id => @resource.id
    assert_response :success
  end

  test "new should render :success" do
    get :new
    assert_response :success
  end

  test "new with customer_id" do
    get :new, :customer_id => @customer.id
    assert_response :success

    assert_select "#resource_customer_name[value=?]", @customer.name
    assert_select "#resource_customer_id[value=?]", @customer.id
  end

  test "edit should render :success" do
    assert @resource.save
    get :edit, :id => @resource.id

    assert_response :success
    assert_select "#resource_customer_name[value=?]", @customer.name
    assert_select "#resource_customer_id[value=?]", @customer.id
  end

end
