require 'spec_helper'
include ScoreRulesHelper

describe ScoreRulesController do
  render_views

  describe "GET 'index'" do

    context 'When the user is not logged in' do
      it 'should redirect to the login page' do
        get :index, :project_id => 0
        expect(response).to redirect_to new_user_session_path
      end
    end

    context 'When the user is logged in' do
      before(:each) do
        sign_in User.make
        @project = Project.make
      end

      it "should render the right template" do
        get :index, :project_id => @project
        expect(response).to render_template :index
      end

      context "When the project doesn't have any score rules" do
        it "should not display any score rules" do
          get :index, :project_id => @project
          expect(response.body).not_to match '<ul id="score_rules">'
        end
      end

      context "when the project have some score rules" do
        before(:each) do
          @score_rule_1 = ScoreRule.make
          @score_rule_2 = ScoreRule.make
          @project.score_rules << @score_rule_1
          @project.score_rules << @score_rule_2
          @project.save
        end

        it "should display a list with all the score rules" do
          get :index, :project_id => @project
          expect(response.body).to match '<table id="score-rules" class="table table-striped table-bordered table-condensed">'
          expect(response.body).to match ERB::Util.h(@score_rule_1.name)
          expect(response.body).to match ERB::Util.h(@score_rule_2.name)
        end
      end

      context "when using an invalid project id" do
        it "should redirect to the project 'index' action" do
          get :index, :project_id => 0
          expect(response).to redirect_to root_path
        end

        it "should display an error message" do
          get :index, :project_id => 0
          expect(flash[:error]).to match 'Invalid project id'
        end
      end
    end
  end

  describe "GET 'new'" do

    context "when the user is not signed in" do

      it "should redirect to the login page" do
        get :new, :project_id => 0
        expect(response).to redirect_to new_user_session_path
      end
    end

    context "when the user has signed in" do

      before(:each) do
        sign_in User.make
        @project = Project.make
      end

      it "should render the right template" do
        get :new, :project_id => @project
        expect(response).to render_template :new
      end

      context "when using an invalid project id" do
        it "should redirect to the project 'index' action" do
          get :new, :project_id => 0
          expect(response).to redirect_to root_path
          #response.should redirect_to projects_path
        end

        it "should display an error message" do
          get :new, :project_id => 0
          expect(flash[:error]).to match 'Invalid project id'
        end
      end

    end
  end

  describe "POST 'create'" do
    context "when the user is not signed in" do
      it "should redirect to the login page" do
        get :new, :project_id => 0
        expect(response).to redirect_to new_user_session_path
      end
    end

    context "when the user is signed in" do
      before(:each) do
        sign_in User.make
        @project = Project.make
        @score_rule ||= ScoreRule.make
        @score_rule_attrs = @score_rule.attributes.with_indifferent_access.slice(:name, :score, :score_type, :exponent)
      end

      context "when using an invalid project id" do
        it "should redirect to the project 'index' action" do
          post :create, :project_id => 0
          expect(response).to redirect_to root_path
        #  response.should redirect_to projects_path
        end

        it "should display an error message" do
          post :create, :project_id => 0
          expect(flash[:error]).to match 'Invalid project id'
        end
      end

      context "when using invalid attributes" do
        before(:each) do
          @score_rule_attrs.merge!('name' => '')
        end

        it "should not create a new score rule" do
          expect {
            post :create, { :score_rule => @score_rule_attrs, :project_id => @project }
          }.to_not change { ScoreRule.count }
        end

        it "should render the 'new' template" do
          post :create, { :score_rule => @score_rule_attrs, :project_id => @project }
          expect(response).to render_template :new
        end

        it "should display some kind of validation error" do
          post :create, { :score_rule => @score_rule_attrs, :project_id => @project }
          expect(response.body).to match '<div class="validation-errors">'
        end

      end

      context "when using valid attributes" do

        it "should create a new score rule" do
          expect {
            post :create, { :score_rule => @score_rule_attrs, :project_id => @project }
          }.to change { ScoreRule.count }.by(1)
        end

        it "should redirect to the 'index' action" do
          post :create, { :score_rule => @score_rule_attrs, :project_id => @project }
          expect(response).to redirect_to container_score_rules_path(@project)
        end

        it "should display a notification" do
          post :create, { :score_rule => @score_rule_attrs, :project_id => @project }
          expect(flash[:success]).to match I18n.t('flash.notice.model_created', model: ScoreRule.model_name.human)
        end
      end
    end
  end

  describe "GET 'edit'" do

     context "when the user is not signed in" do

      it "should redirect to the login page" do
        get :edit, { :project_id => 0, :id => 0 }
        expect(response).to redirect_to new_user_session_path
      end
    end

    context "when the user is signed in" do
      before(:each) do
        sign_in User.make
        @score_rule = ScoreRule.make
        @project    = Project.make(:score_rules => [@score_rule])
      end

      it "should render the right template" do
        get :edit, { :project_id => @project, :id => @score_rule }
        expect(response).to render_template :edit
      end

      context "when using an invalid project id" do
        it "should redirect to the project 'index' action" do
          get :edit, { :project_id => 0, :id => @score_rule }
          expect(response).to redirect_to root_path
          #response.should redirect_to projects_path
        end

        it "should display an error message" do
          get :edit, { :project_id => 0, :id => @score_rule }
          expect(flash[:error]).to match 'Invalid project id'
        end
      end

      context "when using an invalid score rule id" do
        it "should redirect to the project 'index' action" do
          get :edit, { :project_id => @project, :id => 0 }
          expect(response).to redirect_to root_path
          #response.should redirect_to projects_path
        end

        it "should display an error message" do
          get :edit, { :project_id => @project, :id => 0 }
          expect(flash[:error]).to match 'Invalid score rule id'
        end
      end
    end
  end

  describe "PUT 'update'" do

    context "when the user is not signed in" do

      it "should redirect to the login page" do
        put :update, { :project_id => 0, :id => 0 }
        expect(response).to redirect_to new_user_session_path
      end
    end

    context "when the user is signed in" do

      before(:each) do
        sign_in User.make
        @score_rule = ScoreRule.make
        @project    = Project.make(:score_rules => [@score_rule])
        @score_rule_attrs = @score_rule.attributes.with_indifferent_access.slice(:name, :score, :score_type, :exponent)
      end

      context "when using an invalid project id" do
        it "should redirect to the project 'index' action" do
          put :update, { :project_id  => 0,
                         :id          => @score_rule,
                         :score_rule  => @score_rule_attrs }
          expect(response).to redirect_to root_path
          #response.should redirect_to projects_path
        end

        it "should display an error message" do
          put :update, { :project_id  => 0,
                         :id          => @score_rule,
                         :score_rule  => @score_rule_attrs }
          expect(flash[:error]).to match 'Invalid project id'
        end
      end

      context "when using an invalid score rule id" do
        it "should redirect to the project 'index' action" do
          put :update, { :project_id  => @project,
                         :id          => 0,
                         :score_rule  => @score_rule_attrs }
          expect(response).to redirect_to root_path
          #response.should redirect_to projects_path
        end

        it "should display an error message" do
          put :update, { :project_id  => @project,
                         :id          => 0,
                         :score_rule  => @score_rule_attrs }
          expect(flash[:error]).to match 'Invalid score rule id'
        end
      end

      context "when using invalid attributes" do

        before(:each) do
          @score_rule_attrs.merge!('name' => '')
        end

        it "should not update the score rule" do
          expect {
            put :update, { :project_id  => @project,
                           :id          => @score_rule,
                           :score_rule  => @score_rule_attrs }
          }.to_not change { @score_rule.name }
        end

        it "should render the 'edit' template" do
          put :update, { :project_id  => @project,
                         :id          => @score_rule,
                         :score_rule  => @score_rule_attrs }
          expect(response).to render_template :edit
        end

        it "should display some validation error message" do
           put :update, { :project_id  => @project,
                         :id          => @score_rule,
                         :score_rule  => @score_rule_attrs }

          expect(response.body).to match '<div class="validation-errors">'
        end
      end

      context "when using valid attributes" do

        before(:each) do
          @score_rule_attrs.merge!('name' => 'bananas')
        end

        it "should update the score rule" do
          put :update, { :project_id  => @project,
                         :id          => @score_rule,
                         :score_rule  => @score_rule_attrs }
          @score_rule.reload
          expect(@score_rule.name).to match 'bananas'
        end

        it "should redirect to the 'index' action" do
          put :update, { :project_id  => @project,
                         :id          => @score_rule,
                         :score_rule  => @score_rule_attrs }
          expect(response).to redirect_to container_score_rules_path(@project)
        end

        it "should display a notification" do
           put :update, { :project_id  => @project,
                          :id          => @score_rule,
                          :score_rule  => @score_rule_attrs }

          expect(flash[:success]).to match I18n.t('flash.notice.model_updated', model: ScoreRule.model_name.human)
        end
      end
    end
  end

  describe "DELETE 'destroy'" do

    context "when the user is not signed in" do

      it "should redirect to the login page" do
        delete :destroy, { :project_id => 0, :id => 0 }
        expect(response).to redirect_to new_user_session_path
      end
    end


    context "when the user is signed in" do

      before(:each) do
        sign_in User.make
        @score_rule = ScoreRule.make
        @project    = Project.make(:score_rules => [@score_rule])
      end

      context "when using an invalid project id" do
        it "should redirect to the project 'index' action" do
          delete :destroy, :project_id => 0, :id => @score_rule
          expect(response).to redirect_to root_path
          #response.should redirect_to projects_path
        end

        it "should display an error message" do
          delete :destroy, :project_id => 0, :id => @score_rule
          expect(flash[:error]).to match 'Invalid project id'
        end
      end

      context "when using a valid score rule id" do
        it "should delete the score rule" do
          expect {
            delete :destroy, :project_id => @project, :id => @score_rule
          }.to change { ScoreRule.count }.by(-1)
        end

        it "should redirect to the 'index' action" do
          delete :destroy, :project_id => @project, :id => @score_rule
          expect(response).to redirect_to project_score_rules_path(@project)
        end

        it "should display a notification message" do
          delete :destroy, :project_id => @project, :id => @score_rule
          expect(flash[:success]).to match I18n.t('flash.notice.model_deleted', model: ScoreRule.model_name.human)
        end
      end

      context "when using an invalid score rule id" do
        it "should redirect to the project 'index' action" do
          delete :destroy, :project_id => @project, :id => 0
          expect(response).to redirect_to root_path
          #response.should redirect_to projects_path
        end

        it "should display an error message" do
          delete :destroy, :project_id => @project, :id => 0
          expect(flash[:error]).to match 'Invalid score rule id'
        end
      end
    end
  end
end
