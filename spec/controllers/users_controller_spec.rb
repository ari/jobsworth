require 'spec_helper'

include Devise::TestHelpers

describe UsersController do

  before(:each) do
    @company = Company.make!
  end

  shared_examples_for "user with permission to all actions" do

    it "should be able to GET 'list'" do
      get :list
      response.should be_success
    end

    it "should be able to GET 'new'" do
      get :new
      response.should be_success
    end

    it "should be able to GET 'edit'" do
      some_user = User.make!
      get :edit, :id => some_user.id
      response.should be_success
    end

    it "should be able to GET destroy" do
      get :destroy, :id=> user_id=User.make(:company=>@company).id
      response.should be_redirect
      User.find_by_id(user_id).should be_nil
    end

    it "should be able to POST 'create'" do
      new_user = User.make!
      expect {
        post :create, :user => new_user.attributes
      }.to change { User.count }.by(1)
    end

    it "should be able to PUT 'update' (any user)" do
      user = User.make!
      put :update, :id => user.id, :user => user.attributes.merge!(:name => 'newusername')
      User.find(user.id).name.should == 'newusername'
    end
  end

  shared_examples_for "user without permission to admin protected actions" do
    it "should not be able to GET list" do
      get :list
      response.should be_redirect
    end

    it "should not be able to GET 'new'" do
      get :new
      response.should be_redirect
    end

    it "should not be able to GET 'edit'" do
      get :edit, :id=> User.make(:company => @company).id
      response.should be_redirect
    end

    it "should not be able to GET 'destroy'" do
      user = User.make!(:company => @company)
      expect {
        get :destroy, :id => user.id
      }.not_to change { User.count }
    end

    it "should not be able to POST 'create'" do
      post :create, :user=> User.make.attributes.merge!( {'name'=>'username1' })
      response.should be_redirect
      User.find_by_name('username1').should be_nil
    end

    it "should not be able to PUT 'update' (any user)" do
      user = User.make!(:company => @company)
      new_attrs = user.attributes.merge(:name => 'lol')
      put :update, :id => user.id, :user => new_attrs
      user.reload
      user.name.should_not be_equal('lol')
    end
  end

  context "when logged in user is admin," do

    before(:each) do
      Customer.make!

      login_user( 
        :admin?      => true, 
        :admin       => 1, 
        :company_id  => @company.id, 
        :customer_id => Customer.first, 
        :time_zone   => "Europe/Kiev")
    end
    
    it_should_behave_like "user with permission to all actions"
  end

  context "when logged in user is not admin," do

    before(:each) do
      user = User.make!
      sign_in user
    end

    it_should_behave_like "user without permission to admin protected actions"
  end

  context "when logged user is not admin but can edit clients," do
    before(:each) do
      login_user( 
        :admin? => false, 
        :admin  => 0, 
        :company_id => @company.id, 
        :edit_clients? => true, 
        :customer_id => Customer.first, 
        :time_zone=>"Europe/Kiev")
    end

    it_should_behave_like 'user with permission to all actions'
  end
end
