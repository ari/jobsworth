require 'test_helper'

class PropertiesControllerTest < ActionController::TestCase
  fixtures :users, :companies, :properties

signed_in_admin_context do
  def setup
    @request.with_subdomain('cit')
  end
  
  should "render :success on /index" do
    get :index
    assert_response :success
  end

  should "create and redirect on /create " do
    old_count = Property.count

    post(:create, 
         :property => { :name => "Test" },
         :new_property_values => [ 
                                  { :value => 'val1' },
                                  { :value => 'val2' },
                                 ])

    assert_equal old_count + 1, Property.count
    assert_redirected_to(:action => 'edit', :id => assigns["property"])

    created = assigns['property']
    assert_equal "Test", created.name
    assert_equal "val1", created.property_values.first.value
    assert_equal "val2", created.property_values.last.value
    assert_equal "ClockingIT", created.company.name
  end


  should "update and redirect on /update" do
    property = companies(:cit).properties.create
    pv = property.property_values.create(:value => 'val_old')
    old_count = Property.count

    post(:update, 
         :id => property.id,
         :property => { :name => "Test" },
         :property_values => { pv.id.to_s => { :value => "val_old2" } },
         :new_property_values => [ { :value => 'val_new' } ])

    assert_equal old_count, Property.count
    assert_redirected_to :action => 'edit'

    created = assigns['property']
    assert_equal "Test", created.name
    assert_equal "val_old2", created.property_values.first.value
    assert_equal "val_new", created.property_values.last.value
  end

  should "restrict to company on /edit" do
    should_be_restricted(:edit)
  end

  should "restrict to company on /update" do
    should_be_restricted(:update, true, 302)
  end

  should "restrict to company on /destroy" do
    should_be_restricted(:destroy, true, 302)
  end

end
  # Helper to easily test people can only access things in their own company
  def should_be_restricted(action, post = false, expected = :success)
    allowed_property = properties(:first)
    not_allowed = properties(:third)
    method = (post ? :post : :get)

    send(method, action, :id => allowed_property)
    assert_response expected

    begin
      send(method, action, :id => not_allowed)
      assert false
    rescue ActiveRecord::RecordNotFound
      assert true
    end
  end

end


