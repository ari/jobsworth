require "test_helper"

class ClientsControllerTest < ActionController::TestCase
  fixtures :users, :companies, :tasks, :customers

  def setup
    @user = users(:tester)
    @user.update_attributes(:read_clients => false, :edit_clients => false,
                           :create_clients => false)
    @user.admin=false
    @user.save!
    sign_in @user
    @request.session[:user_id] = @user.id
    @client = @user.company.customers.first
    assert_not_nil @client
  end

  test "admin user should be able to access all actions" do
    @user.admin=true
    @user.save!

    get :index
    assert_redirected_to :action => "list"

    get :list
    assert_response :success

    get :new
    assert_response :success

    get :edit, :id => @client.id
    assert_response :success

    post :create, :customer => { :name => "test client" }
    assert_redirected_to :action => "list"

    post :update, :id => @client, :customer => { :name => "test client 2" }
    assert_redirected_to :action => "list"

    post :destroy, :id => @client
    assert_redirected_to :action => "list"
  end

  test "non admin user with create access should be restricted" do
    @user.update_attributes(:create_clients => true)

    get :index
    assert_filter_failed

    get :list
    assert_filter_failed

    get :edit, :id => @client.id
    assert_filter_failed

    get :new
    assert_response :success

    post :create, :customer => { :name => "test client" }
    assert_redirected_to :action => "list"

    post :update, :id => @client, :customer => { :name => "test client 2" }
    assert_filter_failed

    post :destroy, :id => @client
    assert_filter_failed
  end

  test "non admin user with edit access should be restricted" do
    @user.update_attributes(:edit_clients => true)

    get :index
    assert_filter_failed

    get :list
    assert_filter_failed

    get :new
    assert_filter_failed

    get :edit, :id => @client.id
    assert_response :success

    post :create, :customer => { :name => "test client" }
    assert_filter_failed

    post :update, :id => @client, :customer => { :name => "test client 2" }
    assert_redirected_to :action => "list"

    post :destroy, :id => @client
    assert_redirected_to :action => "list"
  end


  test "non admin user with read access should be restricted" do
    @user.update_attributes(:read_clients => true)

    get :index
    assert_redirected_to :action => "list"

    get :list
    assert_response :success

    get :new
    assert_filter_failed

    get :edit, :id => @client.id
    assert_response :success

    post :create, :customer => { :name => "test client" }
    assert_filter_failed

    post :update, :id => @client, :customer => { :name => "test client 2" }
    assert_filter_failed

    post :destroy, :id => @client
    assert_filter_failed
  end

 signed_in_admin_context do
    context "with resources access" do
      setup do
        @user.update_attributes(:use_resources => true)
        get :edit, :id => @client.id
      end

      should "see resources on edit page" do
        assert_tag :tag => "legend", :content => "Resources"
      end
    end

    context "without resources access" do
      setup do
        @user.update_attributes(:use_resources => false)
        get :edit, :id => @client.id
      end

      should "see not resources on edit page" do
        assert_no_tag :tag => "legend", :content => "Resources"
      end
    end
  end

  private

  def assert_filter_failed
    assert_response 302
    assert_equal "Access denied",  @response.flash["notice"]
  end

end
