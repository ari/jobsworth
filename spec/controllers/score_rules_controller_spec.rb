require 'spec_helper'
include ScoreRulesHelper

describe ScoreRulesController do
  render_views

  describe "GET 'index'" do

    context 'When the user is not logged in' do
      it 'should redirect to the login page' do
        get :index, :project_id => 0
        response.should redirect_to '/users/sign_in'
      end
    end

    context 'When the user is logged in' do
      before(:each) do
        sign_in User.make
        @project = Project.make
      end

      it "should render the right template" do
        get :index, :project_id => @project
        response.should render_template :index
      end

      context "When the project doesn't have any score rules" do
        it "should not display any score rules" do
          get :index, :project_id => @project
          response.body.should_not match '<ul id="score_rules">'
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
          response.body.should match '<table id="score-rules" class="table table-striped table-bordered table-condensed">'
          response.body.should match @score_rule_1.name
          response.body.should match @score_rule_2.name
        end
      end

      context "when using an invalid project id" do
        it "should redirect to the project 'index' action" do
          get :index, :project_id => 0
          response.should redirect_to root_path
        end

        it "should display an error message" do
          get :index, :project_id => 0
          flash[:error].should match 'Invalid project id'
        end
      end
    end
  end

  describe "GET 'new'" do
  
    context "when the user is not signed in" do

      it "should redirect to the login page" do
        get :new, :project_id => 0
        response.should redirect_to '/users/sign_in'
      end
    end

    context "when the user has signed in" do
      
      before(:each) do
        sign_in User.make
        @project = Project.make
      end

      it "should render the right template" do
        get :new, :project_id => @project
        response.should render_template :new
      end 

      context "when using an invalid project id" do
        it "should redirect to the project 'index' action" do
          get :new, :project_id => 0
          response.should redirect_to root_path
          #response.should redirect_to projects_path
        end

        it "should display an error message" do
          get :new, :project_id => 0
          flash[:error].should match 'Invalid project id'
        end
      end

    end
  end

  describe "POST 'create'" do
    context "when the user is not signed in" do
      it "should redirect to the login page" do
        get :new, :project_id => 0
        response.should redirect_to '/users/sign_in'
      end
    end

    context "when the user is signed in" do
      before(:each) do
        sign_in User.make
        @project = Project.make
        @score_rule ||= ScoreRule.make
        @score_rule_attrs = @score_rule.attributes
      end

      context "when using an invalid project id" do
        it "should redirect to the project 'index' action" do
          post :create, :project_id => 0
          response.should redirect_to root_path
        #  response.should redirect_to projects_path
        end

        it "should display an error message" do
          post :create, :project_id => 0
          flash[:error].should match 'Invalid project id'
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
          response.should render_template :new
        end

        it "should display some kind of validation error" do
          post :create, { :score_rule => @score_rule_attrs, :project_id => @project }
          response.body.should match '<div class="validation-errors">'
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
          response.should redirect_to container_score_rules_path(@project)
        end
          
        it "should display a notification" do
          post :create, { :score_rule => @score_rule_attrs, :project_id => @project }
          flash[:success].should match 'Score rule created!'
        end
      end
    end
  end

  describe "GET 'edit'" do

     context "when the user is not signed in" do

      it "should redirect to the login page" do
        get :edit, { :project_id => 0, :id => 0 }
        response.should redirect_to '/users/sign_in'
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
        response.should render_template :edit
      end

      context "when using an invalid project id" do
        it "should redirect to the project 'index' action" do
          get :edit, { :project_id => 0, :id => @score_rule }
          response.should redirect_to root_path
          #response.should redirect_to projects_path
        end

        it "should display an error message" do
          get :edit, { :project_id => 0, :id => @score_rule }
          flash[:error].should match 'Invalid project id'
        end
      end

      context "when using an invalid score rule id" do
        it "should redirect to the project 'index' action" do
          get :edit, { :project_id => @project, :id => 0 }
          response.should redirect_to root_path
          #response.should redirect_to projects_path
        end

        it "should display an error message" do
          get :edit, { :project_id => @project, :id => 0 }
          flash[:error].should match 'Invalid score rule id'
        end
      end
    end
  end

  describe "PUT 'update'" do
    
    context "when the user is not signed in" do

      it "should redirect to the login page" do
        put :update, { :project_id => 0, :id => 0 }
        response.should redirect_to '/users/sign_in'
      end
    end

    context "when the user is signed in" do
  
      before(:each) do
        sign_in User.make
        @score_rule = ScoreRule.make
        @project    = Project.make(:score_rules => [@score_rule])
        @score_rule_attrs = @score_rule.attributes
      end

      context "when using an invalid project id" do
        it "should redirect to the project 'index' action" do
          put :update, { :project_id  => 0, 
                         :id          => @score_rule, 
                         :score_rule  => @score_rule_attrs }
          response.should redirect_to root_path
          #response.should redirect_to projects_path
        end

        it "should display an error message" do
          put :update, { :project_id  => 0, 
                         :id          => @score_rule, 
                         :score_rule  => @score_rule_attrs }
          flash[:error].should match 'Invalid project id'
        end
      end

      context "when using an invalid score rule id" do
        it "should redirect to the project 'index' action" do
          put :update, { :project_id  => @project, 
                         :id          => 0, 
                         :score_rule  => @score_rule_attrs }
          response.should redirect_to root_path
          #response.should redirect_to projects_path
        end

        it "should display an error message" do
          put :update, { :project_id  => @project, 
                         :id          => 0, 
                         :score_rule  => @score_rule_attrs }
          flash[:error].should match 'Invalid score rule id'
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
          response.should render_template :edit
        end

        it "should display some validation error message" do
           put :update, { :project_id  => @project, 
                         :id          => @score_rule, 
                         :score_rule  => @score_rule_attrs }

          response.body.should match '<div class="validation-errors">'
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
          @score_rule.name.should match 'bananas'
        end

        it "should redirect to the 'index' action" do
          put :update, { :project_id  => @project, 
                         :id          => @score_rule, 
                         :score_rule  => @score_rule_attrs }
          response.should redirect_to container_score_rules_path(@project)
        end

        it "should display a notification" do
           put :update, { :project_id  => @project, 
                          :id          => @score_rule, 
                          :score_rule  => @score_rule_attrs }

          flash[:success].should match('Score rule updated!')
        end
      end
    end
  end

  describe "DELETE 'destroy'" do

    context "when the user is not signed in" do

      it "should redirect to the login page" do
        delete :destroy, { :project_id => 0, :id => 0 }
        response.should redirect_to '/users/sign_in'
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
          response.should redirect_to root_path
          #response.should redirect_to projects_path
        end

        it "should display an error message" do
          delete :destroy, :project_id => 0, :id => @score_rule
          flash[:error].should match 'Invalid project id'
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
          response.should redirect_to project_score_rules_path(@project)
        end
  
        it "should display a notification message" do
          delete :destroy, :project_id => @project, :id => @score_rule
          flash[:success].should match 'Score rule deleted'
        end
      end

      context "when using an invalid score rule id" do
        it "should redirect to the project 'index' action" do
          delete :destroy, :project_id => @project, :id => 0
          response.should redirect_to root_path
          #response.should redirect_to projects_path
        end

        it "should display an error message" do
          delete :destroy, :project_id => @project, :id => 0
          flash[:error].should match 'Invalid score rule id'
        end
      end
    end
  end
end
