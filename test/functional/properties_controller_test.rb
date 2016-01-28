require 'test_helper'

class PropertiesControllerTest < ActionController::TestCase
  def setup
    @user = User.make(:admin)
    sign_in @user

    project_with_some_tasks(@user)
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
    assert_equal @user.company.name, created.company.name
  end


  should "update and redirect on /update" do
    property = @user.company.properties.create
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

  context "remove property value" do
    should "be able to get remove_property_value_dialog" do
      prop = Property.make(:company => @user.company)
      3.times { PropertyValue.make(:property => prop) }

      get :remove_property_value_dialog, :property_value_id => prop.property_values.first.id
      assert_response :success
    end

    should "be able to remove_property_value directly" do
      prop = Property.make(:company => @user.company)
      3.times { PropertyValue.make(:property => prop) }

      post :remove_property_value, :property_value_id => prop.property_values.first.id

      assert_equal 2, prop.property_values(true).size
    end

    should "be able to remove_property_value by a replace value" do
      prop = Property.make(:company => @user.company)
      3.times { PropertyValue.make(:property => prop) }
      pv_first = prop.property_values.first
      pv_last = prop.property_values.last

      @user.projects.first.tasks.each {|t| TaskPropertyValue.make(:task_id => t.id, :property_id => prop.id, :property_value_id => pv_first.id) }
      TaskFilterQualifier.create(:qualifiable => pv_first)
      assert pv_first.task_filter_qualifiers.count == 1

      post :remove_property_value, :property_value_id => pv_first.id, :replace_with => pv_last.id

      assert_equal 2, prop.reload.property_values.count
      assert_equal 1, pv_last.reload.task_filter_qualifiers.count
      assert_equal @user.projects.first.tasks.count, pv_last.reload.tasks.count
    end
  end

  # Helper to easily test people can only access things in their own company
  def should_be_restricted(action, post = false, expected = :success)
    allowed_property = Property.make(:company => @user.company)
    not_allowed = Property.make(:company => Company.make)
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


