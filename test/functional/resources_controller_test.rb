require File.dirname(__FILE__) + '/../test_helper'

context "Resources" do
  fixtures :companies, :users

  setup do
    use_controller ResourcesController
    @request.with_subdomain("cit")
    user = users(:admin)
    @request.session[:user_id] = user.id

    company = user.company
    @type = company.resource_types.build(:name => "test")
    @type.new_type_attributes = [ { :name => "a1" }, { :name => "a2" } ]
    @type.save!

    @resource = company.resources.build(:name => "test res")
    @resource.resource_type = @type
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
