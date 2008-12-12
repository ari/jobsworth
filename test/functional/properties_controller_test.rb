require 'test_helper'

context "Properties" do
  fixtures :users, :companies
  
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
  end


  specify "/update should update and redirect" do
    property = Property.create
    pv = property.property_values.create(:value => 'val_old')
    old_count = Property.count

    post(:update, 
         :id => property,
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

end


