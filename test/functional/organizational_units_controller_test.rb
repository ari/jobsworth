require 'test_helper'

class OrganizationalUnitsControllerTest < ActionController::TestCase
  fixtures :users, :companies, :customers
  
  def setup
    login
  end
  
  test "/new should render :success" do
    get :new, :customer_id => @user.company.customers.first.id
    assert_response :success
  end

  test "/edit should render :success" do
    org_unit = OrganizationalUnit.new(:name => "test org unit")
    org_unit.save!

    get :new, :id => org_unit.id, :customer_id => @user.company.customers.first.id
    assert_response :success
  end
end

