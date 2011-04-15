require 'test_helper'

class OrganizationalUnitsControllerTest < ActionController::TestCase
  fixtures :users, :companies, :customers
  
  signed_in_admin_context do

  should "render :success on /new" do
    get :new, :customer_id => @user.company.customers.first.id
    assert_response :success
  end

  should "render :success on /edit" do
    org_unit = OrganizationalUnit.new(:name => "test org unit", :customer => @user.company.customers.first)
    org_unit.save!

    get :new, :id => org_unit.id, :customer_id => @user.company.customers.first.id
    assert_response :success
  end
 end
end

