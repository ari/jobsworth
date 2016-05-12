require 'spec_helper'

describe ScmProjectsController do

  before(:each) do
    @scm_project= mock_model(ScmProject)
  end

  describe "GET 'new'" do
    it "should render new template" do
      sign_in_admin
      expect(ScmProject).to receive(:new).and_return(@scm_project)
      get :new
      expect(response).to render_template('scm_projects/new')
    end

    it "should redirect to last url, if user not have create project permission" do
      sign_in_normal_user
      get :new
      expect(response).to  be_redirect
    end
  end

  describe "POST 'create'" do

    context "user with admin permission" do
      let(:scm_params) { { 'scm_type' => 'github', 'location' => 'https://github.com/user/rep' } }

      before(:each) do
        sign_in_admin
      end

      context "with valiad params" do
        before(:each) do
          @scm_project = mock_model(ScmProject, { :save=>true })
          expect(@scm_project).to receive("company=").with(@logged_user.company)

          expect(ScmProject).to receive(:new).
                     with(scm_params).
                     and_return(@scm_project)
        end

        it "should redirect to show action" do
          post :create, scm_project: scm_params
          expect(response).to redirect_to(scm_project_url(@scm_project))
        end
      end

      context "with invalid params" do

        before(:each) do
          @scm_project = mock_model(ScmProject,{ :save => false})
          expect(@scm_project).to receive("company=").with(@logged_user.company)

          expect(ScmProject).to receive(:new).
                     with(scm_params).
                     and_return(@scm_project)
        end

        it "should render new template" do
          post :create, scm_project: scm_params
          expect(response).to render_template('scm_projects/new')
        end
      end
    end

    context "user without admin permission" do

      before(:each) do
        sign_in_normal_user
      end

      it "should redirect to last" do
        post :create, :scm_project =>  { :these => 'params' }
        expect(response).to be_redirect
      end

      it "should not create scm project" do
        expect(ScmProject).not_to receive(:new)
      end
    end
  end
end
