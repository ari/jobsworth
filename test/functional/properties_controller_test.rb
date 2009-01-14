require 'test_helper'

context "Properties" do
  fixtures :users, :companies, :properties
  
  setup do
    use_controller PropertiesController

    @request.with_subdomain('cit')
    @request.session[:user_id] = users(:admin).id
  end
  
  specify "/index should render :success" do
    get :index
    status.should.be :success
  end

  specify "/create should create and redirect" do
    old_count = Property.count

    post(:create, 
         :property => { :name => "Test" },
         :new_property_values => [ 
                                  { :value => 'val1' },
                                  { :value => 'val2' },
                                 ])

    assert_equal old_count + 1, Property.count
    response.should.redirect :action => 'edit'

    created = assigns['property']
    assert_equal "Test", created.name
    assert_equal "val1", created.property_values.first.value
    assert_equal "val2", created.property_values.last.value
    assert_equal "ClockingIT", created.company.name
  end


  specify "/update should update and redirect" do
    property = companies(:cit).properties.create
    pv = property.property_values.create(:value => 'val_old')
    old_count = Property.count

    post(:update, 
         :id => property.id,
         :property => { :name => "Test" },
         :property_values => { pv.id.to_s => { :value => "val_old2" } },
         :new_property_values => [ { :value => 'val_new' } ])

    assert_equal old_count, Property.count
    response.should.redirect :action => 'edit'

    created = assigns['property']
    assert_equal "Test", created.name
    assert_equal "val_old2", created.property_values.first.value
    assert_equal "val_new", created.property_values.last.value
  end

  specify "/edit should restrict to company" do
    should_be_restricted(:edit)
  end

  specify "/update should restrict to company" do
    should_be_restricted(:update, true, 302)
  end

  specify "/destroy should restrict to company" do
    should_be_restricted(:destroy, true, 302)
  end


  # Helper to easily test people can only access things in their own company
  def should_be_restricted(action, post = false, expected = :success)
    allowed_property = properties(:first)
    not_allowed = properties(:third)
    method = (post ? :post : :get)

    send(method, action, :id => allowed_property)
    status.should.be expected

    begin
      send(method, action, :id => not_allowed)
      assert false
    rescue ActiveRecord::RecordNotFound
      assert true
    end
  end

end


