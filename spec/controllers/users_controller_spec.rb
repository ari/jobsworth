require 'spec_helper'

describe UsersController do
  before(:all) do
    name = 'c' + Time.now.to_i.to_s + rand(100).to_s
    @company= Company.make(:name=> name, :subdomain=>name )
  end

  shared_examples_for "user with permission to all actions" do
    it "should be able to GET list" do
      get :list
      response.should be_success
    end

    it "should be able to GET new" do
      get :new
      response.should be_success
    end

    it "should be able to GET edit" do
      get :edit, :id=>User.make(:company=>@company).id
      response.should be_success
    end

    it "should be able to GET destroy" do
      get :destroy, :id=> user_id=User.make(:company=>@company).id
      response.should be_redirect
      User.find_by_id(user_id).should be_nil
    end

    it "should be able to POST create" do
      post :create, :user=> User.make.attributes.merge!( {'name'=>'username1' })
      response.should be_redirect
      User.find_by_name('username1').should_not be_nil
    end

    it "should be able to PUT update (any user)" do
      user= User.make(:company=>@company)
      put :update, :id=>user.id, :user=>user.attributes.merge!(:name=>'newusername')
      User.find(user.id).name.should == 'newusername'
    end
  end

  shared_examples_for "user without permission to admin protected actions" do
    it "should not be able to GET list" do
      get :list
      response.should be_redirect
    end

    it "should not be able to GET new" do
      get :new
      response.should be_redirect
    end

    it "should not be able to GET edit" do
      get :edit, :id=> User.make(:company => @company).id
      response.should be_redirect
    end

    it "should not be able to GET destroy" do
      get :destroy, :id=> user_id=User.make(:company=>@company).id
      response.should be_redirect
      User.find_by_id(user_id).should_not be_nil
    end

    it "should not be able to POST create" do
      post :create, :user=> User.make.attributes.merge!( {'name'=>'username1' })
      response.should be_redirect
      User.find_by_name('username1').should be_nil
    end

    it "should not be able to PUT update (any user)" do
      user= User.make(:company=>@company)
      put :update, :id=>user.id, :user=>user.attributes.merge!(:name=>'newusername')
      User.find(user.id).name.should_not == 'newusername'
    end
  end


  context "when logged in user is admin," do
    before(:each) do
      login_user( 'admin?' => true, 'admin'=>1, 'company_id' =>@company.id )
    end
    it_should_behave_like "user with permission to all actions"
  end

  context "when logged in user is not admin," do
    before(:each) do
      login_user( 'admin?' => false, 'edit_clients?' => false)
    end
    it_should_behave_like "user without permission to admin protected actions"
  end

  context "when logged user is not admin but can edit clients," do
    before(:each) do
      login_user( 'admin?' => false, 'admin'=>0, 'company_id' =>@company.id, 'edit_clients?' => true )
    end
    it_should_behave_like 'user with permission to all actions'
  end
end
