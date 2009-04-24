require File.dirname(__FILE__) + '/../test_helper'

context "Views" do
  fixtures :users, :companies, :tasks, :properties
  
  setup do
    use_controller ViewsController

    @request.with_subdomain('cit')
    @request.session[:user_id] = users(:admin).id
  end
  
  specify "/new should render :success" do
    get :new
    status.should.be :success
  end

  specify "/save_filter should save properties" do
    property = users(:admin).company.properties.first
    value = property.property_values.first

    assert_not_nil value
    @request.session[property.filter_name] = [ value.id.to_s ]

    post :save_filter
    view = assigns["view"]
    assert_redirected_to(:controller => "views", :action => "select", :id => view.id)

    assert_equal value, view.property_values.first
  end

end
