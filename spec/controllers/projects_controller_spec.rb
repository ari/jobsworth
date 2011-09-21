require 'spec_helper'

describe ProjectsController do
  describe "Filters" do
    context "When the logged user is an admin" do
      before :each do
        sign_in_admin
        @project = Project.make(:company => @logged_user.company)
      end

      it "should be authorized to list all the projects" do
        get :index
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
        get :index
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
        attrs = { :name => 'p1', :customer_id => customer.id, :company_id => @logged_user.company.id }
        expect {
          post :create, :project => attrs
        }.to change { Project.count }.by(1)
      end
    end
  end

  describe "GET 'index'" do
    before :each do
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

  describe "GET 'new'" do
    before :each do
      sign_in_admin
    end

    it "should be successful" do
      get :new
      response.should be_success
    end

    it "should render the right template" do
      get :new
      response.should render_template :new
    end
  end

  describe "PUT 'update'" do
    before :each do
      sign_in_admin
    end

    context "When using valid params" do
      context "When the work sheet needs to be updated" do
        before :each do
          @project = Project.make(:company => @logged_user.company)
          @project_attrs = Project.make(:company => @logged_user.company).attributes
          @work_log = WorkLog.make(:project => @project)
        end

        it "should update the Work Sheet accordantly" do
          put :update, :id => @project, :project => @project_attrs
          @work_log.reload
          @work_log.customer_id.should == @project_attrs["customer_id"]
        end
      end

      context "When the Work sheet does not need to be updated" do
        before :each do
          @project = Project.make(:company => @logged_user.company)
          @project_attrs = Project
            .make(:company => @logged_user.company, :customer => @project.customer)
            .attributes
          @work_log = WorkLog.make(:project => @project)
        end

        it "should not update the Work Sheet" do
          put :update, :id => @project, :project => @project_attrs
          @work_log.reload
          @work_log.customer_id.should_not == @project_attrs["customer_id"]
        end
      end
    end
  end
end
