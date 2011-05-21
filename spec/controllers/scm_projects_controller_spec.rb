require 'spec_helper'

describe ScmProjectsController do

  before(:each) do
    @scm_project= mock_model(ScmProject)
  end

  describe "GET 'new'" do
    it "should render new template" do
      sign_in_admin
      ScmProject.should_receive(:new).and_return(@scm_project)
      get :new
      response.should render_template('scm_projects/new')
    end

    it "should redirect to last url, if user not have create project permission" do
      sign_in_normal_user
      get :new
      response.should  be_redirect
    end
  end

  describe "POST 'create'" do

    context "user with admin permission" do

      before(:each) do
        sign_in_admin
      end

      context "with valiad params" do
        before(:each) do
          @scm_project = mock_model(ScmProject, { :save=>true })
          @scm_project.should_receive("company=").with(@logged_user.company)

          ScmProject.should_receive(:new).
                     with('these' => 'params').
                     and_return(@scm_project)
        end

        it "should redirect to show action" do
          post :create, :scm_project => { :these=>'params'}
          response.should redirect_to(scm_project_url(@scm_project))
        end
      end

      context "with invalid params" do

        before(:each) do
          @scm_project = mock_model(ScmProject,{ :save => false})
          @scm_project.should_receive("company=").with(@logged_user.company)

          ScmProject.should_receive(:new).
                     with('these' => 'params').
                     and_return(@scm_project)
        end

        it "should render new template" do
          post :create,:scm_project =>  { :these => 'params' }
          response.should render_template('scm_projects/new')
        end
      end
    end

    context "user without admin permission" do

      before(:each) do
        sign_in_normal_user
      end

      it "should redirect to last" do
        post :create, :scm_project =>  { :these => 'params' }
        response.should be_redirect
      end

      it "should not create scm project" do
        ScmProject.should_not_receive(:new)
      end
    end
  end
end
