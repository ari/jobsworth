require File.dirname(__FILE__) + '/../test_helper'

class ViewsControllerText < ActionController::TestCase
  fixtures :users, :companies, :tasks, :properties
  
  def setup
    use_controller ViewsController

    @request.with_subdomain('cit')
    @request.session[:user_id] = users(:admin).id
  end
  
  test "/new should render :success" do
    get :new
    status.should.be :success
  end

  test "/save_filter should save properties" do
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
