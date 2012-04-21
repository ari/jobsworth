require 'test_helper'

class ServiceLevelAgreementsControllerTest < ActionController::TestCase
  fixtures :users

  setup do
    @user = users(:admin)
    sign_in @user
    @request.session[:user_id] = @user.id
    @service_level_agreement = service_level_agreements(:one)
    @service = services(:one)
    @customer = Customer.make
  end

  test "should create service_level_agreement" do
    assert_difference('ServiceLevelAgreement.count') do
      post :create, service_level_agreement: {:service_id => @service.id, :customer_id => @customer.id}
    end

    assert_response :success
  end

  test "should update service_level_agreement" do
    @service_level_agreement.billable = false
    assert @service_level_agreement.save
    put :update, id: @service_level_agreement.to_param, service_level_agreement: {:billable => true}

    assert_response :success
    assert @service_level_agreement.reload.billable
  end

  test "should destroy service_level_agreement" do
    assert ServiceLevelAgreement.exists?(@service_level_agreement.id)
    assert_difference('ServiceLevelAgreement.count', -1) do
      delete :destroy, id: @service_level_agreement.to_param
    end

    assert_response :success
    assert !ServiceLevelAgreement.exists?(@service_level_agreement.id)
  end

end
