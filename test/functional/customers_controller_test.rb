require "test_helper"

class CustomersControllerTest < ActionController::TestCase
  fixtures :users, :companies, :tasks, :customers, :projects

  def setup
    @user = users(:tester)
    @user.update_attributes(:read_clients => false, :edit_clients => false,
                           :create_clients => false)
    @user.admin = false
    @user.save!
    sign_in @user
    @request.session[:user_id] = @user.id
    @client = @user.company.customers.first
    assert_not_nil @client
  end

  test "admin user should be able to access all actions" do
    @user.admin=true
    @user.save!

    get :new
    assert_response :success

    get :edit, :id => @client.id
    assert_response :success

    post :create, :customer => { :name => "test client" }
    assert_redirected_to root_path

    put :update, :id => @client, :customer => { :name => "test client 2" }
    assert_redirected_to :action => "edit", :id => @client.id

    delete :destroy, :id => @client
    assert_redirected_to root_path
  end

  test "non admin user with create access should be restricted" do
    @user.update_attributes(:create_clients => true)

    get :edit, :id => @client.id
    assert_filter_failed

    get :new
    assert_response :success

    post :create, :customer => { :name => "test client" }
    assert_redirected_to root_path

    put :update, :id => @client, :customer => { :name => "test client 2" }
    assert_filter_failed

    delete :destroy, :id => @client
    assert_filter_failed
  end

  test "non admin user with edit access should be restricted" do
    @user.update_attributes(:edit_clients => true)

    get :new
    assert_filter_failed

    get :edit, :id => @client.id
    assert_response :success

    post :create, :customer => { :name => "test client" }
    assert_filter_failed

    put :update, :id => @client, :customer => { :name => "test client 2" }
    assert_redirected_to :action => "edit", :id => @client.id

    delete :destroy, :id => @client
    assert_redirected_to root_path
  end


  test "non admin user with read access should be restricted" do
    @user.update_attributes(:read_clients => true)

    get :new
    assert_filter_failed

    get :edit, :id => @client.id
    assert_filter_failed

    post :create, :customer => { :name => "test client" }
    assert_filter_failed

    put :update, :id => @client, :customer => { :name => "test client 2" }
    assert_filter_failed

    delete :destroy, :id => @client
    assert_filter_failed
  end

  signed_in_admin_context do
    should "unable to see invisible project in search results" do
      project_hash = {
        name: 'permission test project - invisible',
        description: 'Some description',
        customer_id: customers(:internal_customer).id,
        company_id: companies(:cit).id
      }

      project = Project.create(project_hash)
      assert Project.find(project.id)

      get :search, :term => "test"
      assert_nil assigns["projects"].detect {|p| p.name == project.name}
    end

    should "be able to see visible projects in search results" do
      project_hash = {
        name: 'permission test project - visible',
        description: 'Some description',
        customer_id: customers(:internal_customer).id,
        company_id: companies(:cit).id
      }

      project = Project.create(project_hash)
      assert Project.find(project.id)

      permission = ProjectPermission.new
      permission.user_id = @user.id
      permission.project_id = project.id
      permission.company_id = @user.company_id
      permission.can_comment = 1
      permission.can_work = 1
      permission.can_close = 1
      permission.save

      get :search, :term => "test"
      assert assigns["projects"].detect {|p| p.name == project.name}
    end

    context "with resources access" do
      setup do
        @user.use_resources = true
        @user.save!
        get :edit, :id => @client.id
      end

      should "see resources on edit page" do
        assert_tag :tag => "legend", :content => /Resources/
      end

      should "see resources in search results" do
        company = @user.company
        @type = company.resource_types.build(:name => "test")
        @type.new_type_attributes = [ { :name => "a1" }, { :name => "a2" } ]
        @type.save!

        @resource = company.resources.build(:name => "test res")
        @resource.resource_type = @type
        @resource.customer = @client
        @resource.save!

        get :search, :term => "test"
        assert assigns["resources"].select {|r| r.name == @resource.name}.size > 0

        get :search, :term => "test", :entity => "resource"
        assert assigns["resources"].select {|r| r.name == @resource.name}.size > 0
        assert assigns["users"].size == 0
        assert assigns["customers"].size == 0
        assert assigns["tasks"].size == 0
        assert assigns["projects"].size == 0

        get :search, :term => "test", :entity => "user"
        assert assigns["resources"].size == 0
        assert assigns["customers"].size == 0
        assert assigns["tasks"].size == 0
        assert assigns["projects"].size == 0
      end
    end

    context "without resources access" do
      setup do
        @user.use_resources = false
        @user.save!
        get :edit, :id => @client.id
      end

      should "see not resources on edit page" do
        assert_no_tag :tag => "legend", :content => "Resources"
      end

      should "not see resources in search results" do
        company = @user.company
        @type = company.resource_types.build(:name => "test")
        @type.new_type_attributes = [ { :name => "a1" }, { :name => "a2" } ]
        @type.save!

        @resource = company.resources.build(:name => "test res")
        @resource.resource_type = @type
        @resource.customer = @client
        @resource.save!

        get :search, :term => "test"
        assert assigns["resources"].select {|r| r.name == @resource.name}.size == 0

        get :search, :term => "test", :entity => "resource"
        assert assigns["resources"].select {|r| r.name == @resource.name}.size == 0
        assert assigns["users"].size == 0
        assert assigns["customers"].size == 0
        assert assigns["tasks"].size == 0
        assert assigns["projects"].size == 0

        get :search, :term => "test", :entity => "user"
        assert assigns["resources"].size == 0
        assert assigns["customers"].size == 0
        assert assigns["tasks"].size == 0
        assert assigns["projects"].size == 0
      end

    end
  end

  private

  def assert_filter_failed
    assert_response 302
    assert_equal "Access denied",  flash[:error]
  end

end
