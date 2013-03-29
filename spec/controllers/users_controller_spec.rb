require 'spec_helper'

describe UsersController do

  describe "GET 'index'" do
    before :each do
      Setting.contact_creation_allowed = true
      sign_in_admin
    end

    it "should be successful" do
      get :index
      response.should be_success
    end

    it "should render the right template" do
      get :index
      response.should render_template :index
    end
  end

  shared_examples_for "user with permission to all actions" do

    before(:each) do
      @dummy_user = User.make(:company => @logged_user.company)
    end

    it "should be able to GET index" do
      get :index
      response.should be_success
    end

    it "should be able to GET new" do
      get :new
      response.should be_success
    end

    it "should be able to GET edit" do
      get :edit, :id => @dummy_user
      response.should be_success
    end

    it "should be able to GET destroy" do
      get :destroy, :id => @dummy_user.id
      response.should be_redirect
    end

    it "should be able to delete a user" do
      expect {
        get :destroy, :id => @dummy_user.id
      }.to change { User.count }.by(-1)
    end

    it "should be able to POST create" do
      new_user = User.make
      attrs = new_user.attributes.with_indifferent_access.slice(:name, :password, :customer_id, :date_format, :time_zone, :time_format, :username)
      post :create, :user => attrs, :email => "test@test.com"
      response.should be_redirect
    end

    it "should be able to create a new user" do
      new_user = User.make
      attrs = new_user.attributes.with_indifferent_access.slice(:name, :password, :customer_id, :date_format, :time_zone, :time_format, :username)
      expect {
        post :create, :user => attrs, :email => "test@test.com"
      }.to change { User.count }.by(1)
    end

    it "should be able to update any user" do
      new_attrs = @dummy_user.attributes.merge('name' => 'bananas')
      new_attrs = new_attrs.with_indifferent_access.slice(:name, :password, :customer_id, :date_format, :time_zone, :time_format, :username)
      put :update, :id => @dummy_user, :user => new_attrs
      @dummy_user.reload
      @dummy_user.name.should match 'bananas'
    end
  end

  shared_examples_for "user without permission to admin protected actions" do

    before(:each) do
      @dummy_user = User.make(:company => @logged_user.company)
    end

   it "should not be able to GET index" do
      get :index
      response.should be_redirect
    end

    it "should not be able to GET new" do
      get :new
      response.should be_redirect
    end

    it "should not be able to GET edit" do
      get :edit, :id => @dummy_user
      response.should be_redirect
    end

    it "should not be able to destroy any user" do
      expect {
        get :destroy, :id => @dummy_user
      }.to_not change { User.count }
      response.should be_redirect
    end

    it "should not be able to create a new user" do
      new_user = User.make
      attrs = new_user.attributes.with_indifferent_access.slice(:name, :password, :customer_id, :date_format, :time_zone, :time_format, :username)
      expect {
        post :create, :user => attrs, :email => "test@test.com"
      }.to_not change { User.count }
    end

    it "should not be able to update any user" do
      new_attrs = @dummy_user.attributes.merge('name' => 'bananas')
      new_attrs = new_attrs.with_indifferent_access.slice(:name, :password, :customer_id, :date_format, :time_zone, :time_format, :username)
      put :update, :id => @dummy_user, :user => new_attrs
      @dummy_user.reload
      @dummy_user.name.should_not match 'bananas'
    end
  end


  context "when logged in user is admin," do
    before(:each) do
      Setting.contact_creation_allowed = true
      sign_in_admin
    end

    it_should_behave_like "user with permission to all actions"
  end

  context "when logged in user is not admin," do
    before(:each) do
      Setting.contact_creation_allowed = true
      sign_in_normal_user
    end

    it_should_behave_like "user without permission to admin protected actions"
  end

  context "when logged in user is admin, but contact creation is disabled in app" do
    before(:each) do
      Setting.contact_creation_allowed = false
      sign_in_admin
    end

    it_should_behave_like "user without permission to admin protected actions"
  end


  context "when logged user is not admin but can edit clients," do
    before(:each) do
      Setting.contact_creation_allowed = true
      sign_in_normal_user(:edit_clients => true)
    end

    it_should_behave_like 'user with permission to all actions'
  end
end
