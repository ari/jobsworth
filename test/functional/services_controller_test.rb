require 'test_helper'

class ServicesControllerTest < ActionController::TestCase
  setup do
    @user = users(:admin)
    sign_in @user
    @request.session[:user_id] = @user.id

    @service = services(:one)
    @service.company = @user.company
    @service.save
  end

  test "should get index" do
    get :index
    assert_response :success
    assert_not_nil assigns(:services)
  end

  test "should get new" do
    get :new
    assert_response :success
  end

  test "should create service" do
    assert_difference('Service.count') do
      post :create, service: {:name => "test service"}
    end

    assert_redirected_to services_path
  end

  test "should show service" do
    get :show, id: @service.to_param
    assert_response :success
  end

  test "should get edit" do
    get :edit, id: @service.to_param
    assert_response :success
  end

  test "should update service" do
    put :update, id: @service.id, service: @service.attributes

    assert_redirected_to services_path
  end

  test "should destroy service" do
    assert Service.exists?(@service.id)
    delete :destroy, id: @service.to_param
    assert_redirected_to services_path

    assert !Service.exists?(@service.id)
  end

  test "should be able to get auto_complete_for_service_name" do
    assert Service.exists?(@service.id)
    get :auto_complete_for_service_name, :term => @service.name

    assert_response :success
    assert assigns(:services).detect {|s| s.name == @service.name }
  end

end
