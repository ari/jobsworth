require 'test_helper'

class ProjectsControllerTest < ActionController::TestCase
  fixtures :customers, :projects

  signed_in_admin_context do
    setup do
      @project = projects(:test_project)
    end

    should "get list page" do
      get :index
      assert_response :success
    end

    should "get new project page" do
      get :new
      assert_response :success
    end

    should "get project view page" do
      get :show, :id => @project.id
      assert_response :success
    end

    should "create project and copy project permissions" do
      project_hash = {
        name: 'New Project',
        description: 'Some description',
        customer_id: customers(:internal_customer).id,
        company_id: companies(:cit).id
      }
      assert_difference("Project.count", +1) do
        post :create, {
          project: project_hash,
          copy_project_id: @project.id
        }
      end
      assert_equal 3, assigns[:project].project_permissions.size
      assert_redirected_to :action => :index
    end

    should "get edit project page" do
      get :edit, :id => @project.id
      assert_response :success
    end

    should "update project" do
      post :update, {:project=>{:name=>"New Project Name", :description=>"New Project Description",
                     :customer_id=>customers(:internal_customer).id},
                     :id=>@project.id,
                     :customer=>{:name=>customers(:internal_customer).name}}
      assert_equal "New Project Name", assigns[:project].name
      assert_equal "New Project Description", assigns[:project].description
      assert_redirected_to :action=> "index"
    end

    should "complete project" do
      get :complete, {:id => @project.id}
      assert_not_nil @project.reload.completed_at
      assert_redirected_to root_url
    end

    should "revert project" do
      get :revert, {:id => projects(:completed_project).id}
      assert_nil projects(:completed_project).reload.completed_at
      assert_redirected_to root_url
    end
    context "destroy project" do
      setup do
        task = Task.make
        @project.sheets << Sheet.make(:user => @user, :task => task)
        @project.pages << Page.make(:notable => @project)
        @project.work_logs << WorkLog.make(:user => @user)
      end

      context "without tasks" do
        setup do
          other = Project.where("id !=?", @project.id).first
          @project.tasks.each{ |task|
            task.project=other
            task.save!
          }
        end
        should "remove project and its worklogs, tasks, pages, milestones, sheets, project permissions" do
          assert_difference("Project.count", -1) do
            delete :destroy, :id => @project.id
          end
          assert_equal 0, Page.where(:notable_id => @project.id, :notable_type => "Project").count
          assert_equal 0, Task.where(:project_id => @project.id).count
          assert_equal 0, WorkLog.where(:project_id => @project.id).count
          assert_equal 0, Milestone.where(:project_id => @project.id).count
          assert_equal 0, Sheet.where(:project_id => @project.id).count
          assert_equal 0, ProjectPermission.where(:project_id => @project.id).count
          assert_redirected_to :action=> "index"
        end
      end
      context "with tasks" do
        should "reject destroy action" do
          assert_no_difference("Project.count") do
            delete :destroy, :id => @project.id
          end
          assert_not_equal 0, Task.where(:project_id => @project.id).count
          assert_not_equal 0, Page.where(:notable_id => @project.id, :notable_type => "Project").count
          assert_not_equal 0, WorkLog.where(:project_id => @project.id).count
          assert_not_equal 0, Milestone.where(:project_id => @project.id).count
          assert_not_equal 0, Sheet.where(:project_id => @project.id).count
          assert_not_equal 0, ProjectPermission.where(:project_id => @project.id).count
        end
      end
    end
  end
end
