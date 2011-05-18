require 'spec_helper'
include Devise::TestHelpers

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
          response.body.should match '<ul id="score-rules">'
          response.body.should match @score_rule_1.name
          response.body.should match @score_rule_2.name
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
    end
  end
end
