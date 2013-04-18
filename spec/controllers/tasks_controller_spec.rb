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

  describe "GET 'new'" do
    before :each do
      sign_in_normal_user
    end

    context "When the logged user has projects" do
      before :each do
        @logged_user.projects << Project.make
        @logged_user.save
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

    context "When the logged user doesn't has projects" do
      it "should redirect to the 'new' action on the Projects controller" do
        get :new
        response.should redirect_to new_project_path
      end

      it "should indicated the user that it need to create a new project" do
        get :new
        flash[:alert].should match I18n.t('hint.task.project_needed')
      end
    end
  end

  describe "POST 'create'" do
    before :each do
      sign_in_normal_user
    end

    context "When the user is not authorized to create a task in the selected project" do
      before :each do
        @project = Project.make
        @logged_user.projects << @project
        @logged_user.save
        @task_attrs = TaskRecord.make(:project => @project).attributes.with_indifferent_access.except(:id, :type)

        controller.current_user.stub!(:can?).and_return(false)
      end

      it "should not create a new Task instance" do
        expect {
          post :create, :task => @task_attrs
        }.to_not change { TaskRecord.count }
      end

      it "should render the 'new' template" do
        post :create, :task => @task_attrs
        response.should render_template :new
      end

      it "should indicate the user that the task could not be created" do
        post :create, :task => @task_attrs
        flash[:error].should match I18n.t('flash.alert.unauthorized_operation')
      end
    end

    context "When the user is authorized to create task under the selected project" do
      before :each do
        @project = Project.make
        @logged_user.projects << @project
        @logged_user.save
        @task_attrs = TaskRecord.make(:project => @project).attributes.with_indifferent_access.except(:id, :type)

        controller.stub!('parse_time').and_return(10)
        controller.current_user.stub!(:can?).and_return(true)
      end

      it "should craete a new task instance" do
        expect {
          post :create, :task => @task_attrs
        }.to change { TaskRecord.count }.by(1)
      end

      it "should redirect to the 'index' action on the Tasks controller" do
        post :create, :task => @task_attrs
        response.should redirect_to tasks_path
      end
    end
  end

  describe "#score" do
    context "when the user is not signed in" do
      it "should redirect to the sign_in page" do
        get :score, :id => 1
        response.should redirect_to new_user_session_path
      end
    end

    context "when the user is singed in, but using an invalid task_num" do
      before(:each) do
        sign_in_normal_user
      end

      it "should redirect to '#list'" do
        get :score, :id => 0
        response.should redirect_to 'index'
      end

      it "should show an error message" do
        get :score, :id => 0
        flash[:error].should match I18n.t('activerecord.errors.models.task_record.task_number.invalid')
      end
    end

    context "when the user is signed in, and using a valid task_num" do
      before(:each) do
        sign_in_normal_user
      end

      context "when the task has some score rules" do
        before(:each) do
          project     = Project.make
          @task       = TaskRecord.make(:task_num => 123)
          @score_rule = ScoreRule.make

          project.score_rules << @score_rule
          project.tasks << @task
          ProjectPermission.create(:user => @logged_user, :company => @logged_user.company, :project => project)

          # As of right now, the only way to recalculate the score is by modifying the task
          @task.save(:validate => false)
        end

        it "should be successful" do
          get :score, :id => @task.task_num
          response.should be_success
        end

        it "should render the task score" do
          get :score, :id => @task.task_num
          response.body.should match "Score: #{@task.weight}"
        end

        it "should render the task score_adjustment" do
          get :score, :id => @task.task_num
          response.body.should match "Score Adjustment: #{@task.weight_adjustment}"
        end

        it "should render a table with all the score rules" do
          get :score, :id => @task.task_num
          response.body.should match @score_rule.name
          response.body.should match @score_rule.score.to_s
          response.body.should match @score_rule.exponent.to_s
          response.body.should match @score_rule.score_type.to_s
        end
      end
    end

  end
end
