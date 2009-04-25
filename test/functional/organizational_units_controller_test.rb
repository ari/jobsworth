require 'test_helper'

context "OrganizationalUnits" do
  fixtures :users, :companies, :customers
  
  setup do
    use_controller OrganizationalUnitsController

    @request.with_subdomain('cit')
    @user = users(:admin)
    @request.session[:user_id] = @user.id
  end
  
  specify "/new should render :success" do
    get :new, :customer_id => @user.company.customers.first.id
    status.should.be :success
  end

  specify "/edit should render :success" do
    org_unit = OrganizationalUnit.new(:name => "test org unit").save!
    get :new, :id => org_unit.id, :customer_id => @user.company.customers.first.id
    status.should.be :success
  end
end

