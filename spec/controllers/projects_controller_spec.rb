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
        expect(response).to be_success
      end

      it "should be authized to access edit a project" do
        get :edit, :id => @project
        expect(response).to be_success
      end

      it "should be authorized to update a project" do
        put :update, :id => @project, :project => { :name => 'some_name' }
        @project.reload
        expect(@project.name).to match 'some_name'
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
        expect(response).to be_success
      end

      it "should be able to list all completed projects" do
        get :list_completed
        expect(response).to be_success
      end

      it "should be able to create a new project" do
        get :new
        expect(response).to be_success
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
      expect(response).to be_success
    end

    it "should render the right template" do
      get :index
      expect(response).to render_template :index
    end
  end

  describe "GET 'new'" do
    before :each do
      sign_in_admin
    end

    it "should be successful" do
      get :new
      expect(response).to be_success
    end

    it "should render the right template" do
      get :new
      expect(response).to render_template :new
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
          expect(@work_log.customer_id).to eq(@project_attrs["customer_id"])
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
          expect(@work_log.customer_id).not_to eq(@project_attrs["customer_id"])
        end
      end
    end
  end

  describe "Create Project without customer" do
    before :each do
      sign_in_normal_user({:company_id => 1})
    end

    it "should create and assign new project to internal customer" do
        customer = Customer.make(:company_id => @logged_user.company_id, :name => "Internal")
        post :create,  { "project"=>{"name"=>"Test project", "default_estimate"=>"1.0",
                         "customer_id"=>"0", "description"=>"Attach to internal customer by default"},
                         "customer"=>{"name"=>""}, "copy_project"=>"0"}
        expect(assigns(@project)[:project].customer_id).to eq(customer.id)
    end
  end
end
