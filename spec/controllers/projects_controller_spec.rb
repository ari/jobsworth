require 'spec_helper'

describe ProjectsController do
  describe "Filters" do
    context "When the logged user is an admin" do
      before :each do
        sign_in_admin
        @project = Project.make(:company => @logged_user.company)
      end

      it "should be authorized to list all the projects" do
        get :list
        response.should be_success
      end

      it "should be authized to access edit a project" do
        get :edit, :id => @project
        response.should be_success
      end

      it "should be authorized to update a project" do
        put :update, :id => @project, :project => { :name => 'some_name' } 
        @project.reload
        @project.name.should match 'some_name'
      end

      it "should be authorized to delete a project" do
        expect {
          delete :destroy, :id => @project
        }.to change { Project.count }.by(-1)
      end
    end

    context "When the logged user is not an admin" do
      before :each do
        sign_in_normal_user
      end

      it "should be able to list all projects" do
        get :list
        response.should be_success
      end

      it "should be able to list all completed projects" do
        get :list_completed
        response.should be_success
      end

      it "should be able to create a new project" do
        get :new
        response.should be_success
      end

      it "should be able to create a new project instance" do
        customer = Customer.make
        attrs = { :name => 'p1', :customer => customer, :company => @logged_user.company }
        expect {
          post :create, :project => attrs
        }.to change { Project.count }.by(1)
      end
    end
  end
end
