require File.dirname(__FILE__) + '/../test_helper'

describe "ResourceTypesController", ActionController::TestCase do
  fixtures :companies, :users

  setup do
    use_controller ResourceTypesController
    @request.with_subdomain("cit")
    user = users(:admin)
    user.use_resources = true
    user.save!
    @request.session[:user_id] = user.id

    company = user.company
    @type = company.resource_types.build(:name => "test")
    @type.new_type_attributes = [ { :name => "a1" }, { :name => "a2" } ]
    @type.save!

    @resource = company.resources.build(:name => "test res")
    @resource.resource_type = @type
  end

  specify "all should redirect if not admin set on user" do
    user = User.find(@request.session[:user_id])
    user.admin = false
    user.save!

    end_page = { :controller => "activities", :action => "list" }

    get :new
    assert_redirected_to(end_page)

    get :edit, :id => @type.id
    assert_redirected_to(end_page)

    post :create, :id => @type.id
    assert_redirected_to(end_page)

    post :update, :id => @type.id
    assert_redirected_to(end_page)

    post :destroy, :id => @type.id
    assert_redirected_to(end_page)
  end 


end
