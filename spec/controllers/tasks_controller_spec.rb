require 'spec_helper'

describe TasksController do
  render_views

  describe "GET 'index'" do
    before :each do
      sign_in_normal_user
    end

    it "should be successful" do
      get :index
      response.should be_success
    end

    it "should render the right template" do
      get :index
      response.should render_template :index
    end

    it "should be successful when the format requested is json" do
      get :index, :format => :json
      response.should be_success
    end

    it "should render the right template when the format requested is json" do
      get :index, :format => :json
      response.should render_template 'tasks/index'
    end
  end

  describe "#score" do

    context "when the user is not signed in" do
      it "should redirect to the sign_in page" do
        get :score, :task_num => 1
        response.should redirect_to '/users/sign_in'
      end
    end

    context "when the user is singed in, but using an invalid task_num" do
      before(:each) do
        sign_in_normal_user
      end

      it "should redirect to '#list'" do
        get :score, :task_num => 0
        response.should redirect_to 'list'
      end

      it "should show an error message" do
        get :score, :task_num => 0
        flash[:error].should match 'Invalid Task Number'
      end 
    end

    context "when the user is signed in, and using a valid task_num" do
      before(:each) do
        sign_in_normal_user
      end

      context "when the task has some score rules" do
        before(:each) do
          project     = Project.make
          @task       = Task.make(:task_num => 123)
          @score_rule = ScoreRule.make

          project.score_rules << @score_rule
          project.tasks << @task

          # As of right now, the only way to recalculate the score is by modifying the task 
          @task.save(:validate => false) 
        end

        it "should be successful" do
          get :score, :task_num => @task.task_num
          response.should be_success 
        end

        it "should render the task score" do
          get :score, :task_num => @task.task_num
          response.body.should match "Score: #{@task.weight}"
        end

        it "should render the task score_adjustment" do
          get :score, :task_num => @task.task_num
          response.body.should match "Score Adjustment: #{@task.weight_adjustment}"
        end

        it "should render a table with all the score rules" do
          get :score, :task_num => @task.task_num
          response.body.should match @score_rule.name
          response.body.should match @score_rule.score.to_s
          response.body.should match @score_rule.exponent.to_s
          response.body.should match @score_rule.score_type.to_s
        end
      end
    end
   
  end
end
