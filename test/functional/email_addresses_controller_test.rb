require 'test_helper'

class EmailAddressesControllerTest < ActionController::TestCase
  setup do
    @user = users(:admin)
    sign_in @user
    @request.session[:user_id] = @user.id

    @email_address = EmailAddress.make(:company => @user.company)
  end

  test "should get index" do
    get :index
    assert_response :success
    assert_not_nil assigns(:email_addresses)
    assert assigns(:email_addresses).include?(@email_address)
  end

  test "should get edit" do
    get :edit, id: @email_address.id
    assert_response :success
  end

  test "should update service" do
    put :update, id: @email_address.id, email_address: @email_address.attributes

    assert_response :success
  end
end
