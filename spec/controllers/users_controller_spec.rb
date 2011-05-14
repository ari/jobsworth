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
      some_user = User.make!(:company => @company)
      get :edit, :id => some_user.id
      response.should be_success
    end

    it "should be able to DELETE 'destroy'" do
      some_user = User.make!(:company => @company)
      expect {
        delete :destroy, :id => some_user.id
      }.to change { User.count }.by(-1)
    end

    it "should be able to POST 'create'" do
      new_user = User.make!
      expect {
        post :create, :user => new_user.attributes
      }.to change { User.count }.by(1)
    end

    it "should be able to PUT 'update' (any user)" do
      some_user = User.make!(:company => @company)
      new_attrs = some_user.attributes.merge(:name => 'bananas')
      put :update, :id => some_user.id, :user => new_attrs
      some_user.reload
      some_user.name.should == 'bananas'
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
      get :edit, :id => User.make(:company => @company).id
      response.should be_redirect
    end

    it "should not be able to DELETE 'destroy'" do
      user = User.make!(:company => @company)
      expect {
        delete :destroy, :id => user.id
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
      user.name.should_not == 'lol'
    end
  end

  context "when logged in user is admin," do

    before(:each) do
      user = User.make!(:admin => 1, :company => @company)
      sign_in user
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
      user = User.make!(:admin => 0, :company => @company, :edit_clients => true)
      sign_in user
    end

    it_should_behave_like 'user with permission to all actions'
  end
end
