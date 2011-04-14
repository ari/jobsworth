require 'test_helper'

class TasksControllerTest < ActionController::TestCase
  fixtures :users, :companies, :tasks, :customers, :projects, :properties, :property_values

signed_in_admin_context do
  def setup
    @request.with_subdomain('cit')
  end

  should "render :success on /edit" do
    task = tasks(:normal_task)

    get :edit, :id => task.task_num
    assert_response :success
  end

  should "find task by task num on /edit" do
    task = tasks(:normal_task)
    task.update_attribute(:task_num, task.task_num - 1)

    get :edit, :id => task.task_num
    assert_equal task, assigns["task"]

    get :edit, :id => task.id
    assert_not_equal task, assigns["task"]
  end

  should "render :success on /new" do
    get :new
    assert_response :success
  end

  should "render :success on /list" do
    company = companies("cit")

    # need to create a task to ensure the task partials get rendered
    task = Task.new(:name => "Test", :project_id => company.projects.last.id)
    task.company = company
    task.save!

    get :list
    assert_response :success
    assert TaskFilter.system_filter(@user).tasks.include?(task)
#    assert assigns["tasks"].include?(task)
  end

  should "render form ok when failing update on /update" do
    task = Task.first
    # post something that will cause a validation to fail
    post(:update, :id => task.id, :task => { :name => "" })

    assert_response :success
  end

  should "render error message on name when name not presented on /update" do
    task = Task.first
    post(:update, :id => task.id, :task => { :name => "" })
    assert assigns['task'].errors[:name].any?
  end

  should "render error message on project when project not presented on /update" do
    task = Task.first
    post(:update, :id => task.id, :task => { :project_id =>""})
    assert assigns['task'].errors[:project_id].any?
  end

  should "render JSON error message when validation failed on /update?format=js" do
    task = Task.first
    post(:update, :format => 'js', :id => task.id, :task => { :project_id =>""})
    assert assigns['task'].errors[:project_id].any?
    json_response = ActiveSupport::JSON.decode(@response.body)
    assert_equal({"messages"=>["Project can't be blank"], "status"=>"error"}, json_response)
  end

  context "a task with a few users attached" do
    setup do
      ActionMailer::Base.deliveries = []
      @task = tasks(:normal_task)
      @task.users << @task.company.users
      @task.status=0
      @task.save!
      assert_emails 0
    end
    teardown do
      @task.work_logs.destroy_all
    end

    should "render JSON when adding a comment and attachment with Ajax" do
      post(:update, :id => @task.id, :task => { }, :format => "js",
           :users=> @task.user_ids,
           :comment => "a test comment",
           :tmp_files => [Rails.root.join('test', 'fixtures', 'files', 'rails.png').open])
      json_response = ActiveSupport::JSON.decode(@response.body)
      attachments = @task.reload.attachments
      assert_equal 1, attachments.size
      assert_equal "success", json_response["status"]
      assert_equal @task.task_num, json_response["tasknum"]
      #check attachment
      uri =  attachments.first.uri
      assert_equal true, File.exist?(Rails.root.join('store', "#{uri}_original.png"))
      assert_equal true, File.exist?(Rails.root.join('store', "#{uri}_thumbnail.png"))
      @task.attachments.destroy_all
    end

    should "prevent duplication of files when adding the same attachment to two tasks" do
      count_files = Dir.entries(Rails.root.join("store")).size

      post(:update, :id => @task.id, :task => { }, :format => "js",
           :users=> @task.user_ids,
           :tmp_files => [Rails.root.join('test', 'fixtures', 'files', 'rails.png').open])

      @second_task = Task.last
      @second_task.users << @second_task.company.users
      @second_task.status=0
      @second_task.save!

      post(:update, :id => @second_task.id, :task => { }, :format => "js",
           :users=> @second_task.user_ids,
           :tmp_files => [Rails.root.join('test', 'fixtures', 'files', 'rails.png').open])

      #total filenames in the 'store' directory should increment by 2 (uri_original and uri_thumbnail)
      assert_equal count_files + 2, Dir.entries(Rails.root.join("store")).size
      @second_task.attachments.destroy_all
    end
    should "get 'Unauthorized' when adding a comment and session has timed out" do
      sign_out @user
      post(:update, :id => @task.id, :task => { }, :format => "js",
           :users=> @task.user_ids,
           :comment => "a test comment")
      assert_equal "Unauthorized", @response.message
    end
    should "send emails to each user when adding a comment" do
      post(:update, :id => @task.id, :task => { },
           :users=> @task.user_ids,
           :comment => "a test comment")
      assert_emails @task.users.length
      assert_response :redirect
    end
    should "send unescaped html in email" do
      @task.name= name_html = "<strong>name</strong> ; <script> alert('XSS');</script>"
      @task.description= description_html = "<strong>description</strong> ; <script> alert('XSS');</script>"
      @task.save!
      comment_html = "<strong>comment</strong> ; <script> alert('XSS');</script>"
      post(:update, :id => @task.id, :task => { },
           :users=> @task.user_ids,
           :comment => comment_html)
      @task.reload
      assert_emails @task.users.length
      assert_response :redirect
      mail = ActionMailer::Base.deliveries.first
      assert_match name_html, mail.body
      assert_match description_html, mail.body
      assert_match comment_html, mail.body
    end
    should "update group when user dragging task on task grid" do
      # custom property
      TaskPropertyValue.make(:task_id => @task.id, :property_id => properties(:first).id,
                             :property_value_id => property_values(:first).id)

      post :set_group, :id => @task.task_num, :group => properties(:first).name, :value => property_values(:first).value
      tpv = @task.task_property_values.reload.detect { |tpv| tpv.property_id == properties(:first).id }
      assert_equal property_values(:first).id, tpv.property_value_id

      post :set_group, :id => @task.task_num, :group => properties(:first).name, :value => property_values(:second).value
      tpv = @task.task_property_values.reload.detect { |tpv| tpv.property_id == properties(:first).id }
      assert_equal property_values(:second).id, tpv.property_value_id

      #milestone
      milestone = @user.company.milestones.rand
      post :set_group, :id => @task.task_num, :group => 'milestone', :value => "#{milestone.project.name}/#{milestone.name}"
      assert_equal milestone.id, @task.reload.milestone_id

      #resolution
      resolution_arr = @task.statuses_for_select_list.clone.delete_if{|x| x[1] == @task.status}.rand
      post :set_group, :id => @task.task_num, :group => "resolution", :value=> resolution_arr[0]
      assert_equal resolution_arr[1], @task.reload.status
    end

    context "one of task's watched attributes changed," do
      setup do
        @parameters={:id=>@task.id, :task=>{ :name=>"ababa-galamaga"}, :users=>  @task.user_ids, :assigned=>@task.owner_ids}
      end
      context "with comment added," do
        setup do
          @parameters.merge!(:comment=>'Just a comment')
        end
        context "with time spend" do
          setup do
            @parameters.merge!(:work_log=>{ :duration=>'10m',:started_at=>Time.now.utc.to_s})
            post(:update,@parameters)
            assert_response :redirect
          end
          should "create work log with type according to changes, with (changes+comment) as a body, without time and send it" do
            worklog=@task.work_logs.find_by_log_type(EventLog::TASK_MODIFIED)
            assert_not_nil worklog
            assert_equal worklog.duration, 0
            assert worklog.body =~ /name/i, "work log body must include changes "
            assert worklog.body =~ /#{@parameters[:comment]}/, "work log body must include comment"
          end
          should "create work log with type TASK_WORK_ADDED, with comment as a body, with time spend, and not  send it" do
            worklog=@task.work_logs.find_by_log_type(EventLog::TASK_WORK_ADDED)
            assert_not_nil worklog
            assert_equal worklog.duration, 10*60
            assert worklog.body =~ /#{@parameters[:comment]}/, "work log body must include comment"
          end
          should "send one email to each user" do
            assert_emails  @task.users.length
            assert_equal @task.work_logs.count, 2
          end
        end
        context "without time spend" do
          setup do
            @parameters.merge!(:work_log=>{ })
            post(:update,@parameters)
            assert_response :redirect
          end
          should "create work log with type according to changes, with (changes + comment) as a body, without time and send it" do
            worklog=@task.work_logs.find_by_log_type(EventLog::TASK_MODIFIED)
            assert_not_nil worklog
            assert_equal worklog.duration, 0
            assert worklog.body =~ /name/i, "work log body must include changes "
            assert worklog.body =~ /#{@parameters[:comment]}/, "work log body must include comment"
          end
          should "send one email to each user" do
            assert_emails  @task.users.length
            assert_equal @task.work_logs.count, 1
          end
        end
      end
      context "without comment," do
        setup do
          @parameters.merge!(:comment=>'')
        end
        context "with time spend" do
          setup do
            @parameters.merge!(:work_log=>{ :duration=>'10m',:started_at=>Time.now.utc.to_s})
            post(:update,@parameters)
            assert_response :redirect
          end
          should "create work log with type according to changes, with changes as a body, without time and not send it" do
            worklog=@task.work_logs.find_by_log_type(EventLog::TASK_MODIFIED)
            assert_not_nil worklog
            assert_equal worklog.duration, 0
            assert worklog.body =~ /name/i, "work log body must include changes "
          end
          should "create work log with type TASK_WORK_ADDED, without any comment, with time spend and not send it" do
            worklog=@task.work_logs.find_by_log_type(EventLog::TASK_WORK_ADDED)
            assert_not_nil worklog
            assert_equal worklog.duration, 10*60
            assert !(worklog.body =~ /name/i), "work log body must not include changes"
          end
          should "not send any emails" do
            assert_emails 0
            assert_equal @task.work_logs.count, 2
          end
        end
        context "without time spend" do
          setup do
            @parameters.merge!(:work_log=>{ })
            post(:update,@parameters)
            assert_response :redirect
          end
          should "create work log with type according to changes, with changes as a body, without time and not send it" do
            worklog=@task.work_logs.find_by_log_type(EventLog::TASK_MODIFIED)
            assert_not_nil worklog
            assert_equal worklog.duration, 0
            assert worklog.body =~ /name/i, "work log body must include changes "
          end
          should "not send any emails" do
            assert_emails 0
            assert_equal @task.work_logs.count, 1
          end
        end
      end
    end
    context "without changes to task's watched attributes" do
      setup do
        @parameters={:id=>@task.id, :assigned=>@task.user_ids, :task=>{}, :users=> @task.user_ids}
      end
      context "with comment added," do
        setup do
          @parameters.merge!(:comment=>'Just a comment')
        end
        context "with time spend" do
          setup do
            @parameters.merge!(:work_log=>{:duration=>'10m',:started_at=>Time.now.utc.to_s })
            assert_equal 0, @task.work_logs.count, 'before call update task don\'t have worklogs'
            post(:update, @parameters)
            assert_response :redirect
          end
          should "create work log with type TASK_WORK_ADDED, with comment as a body, with time spend and send it" do
            worklog=@task.work_logs.find_by_log_type(EventLog::TASK_WORK_ADDED)
            assert_not_nil worklog
            assert_equal worklog.duration, 10*60
            assert worklog.body =~ /#{@parameters[:comment]}/, "work log body must include comment"
          end
          should "send only one email to each user and create only one work log" do
            assert_emails @task.users.length
            assert_equal 1, @task.work_logs.count,  'number of work logs'
          end
        end
        context "without time spend" do
          setup do
            @parameters.merge!(:work_log=>{ })
            post(:update, @parameters)
            assert_response :redirect
          end
          should "create work log with type TASK_COMMENT, with comment as a body and send it" do
            worklog=@task.work_logs.find_by_log_type(EventLog::TASK_COMMENT)
            assert_not_nil worklog, "#{@parameters} #{}"
            assert_equal worklog.duration, 0
            assert worklog.body =~ /#{@parameters[:comment]}/, "work log body must include comment"
          end
          should "send one email to each user and create only one worklog" do
            assert_emails @task.users.length
            assert_equal 1, @task.work_logs.count
          end
        end
      end
      context "without comment," do
        setup do
          @parameters.merge!( :comment => nil)
        end
        context "with time spend" do
          setup do
            @parameters.merge!(:work_log=>{:duration=>'10m',:started_at=>Time.now.utc.to_s })
            post(:update, @parameters)
            assert_response :redirect
          end
          should "create work log with type TASK_WORK_ADDED, without body, and not send it" do
            worklog=@task.work_logs.find_by_log_type(EventLog::TASK_WORK_ADDED)
            assert_not_nil worklog
            assert_equal worklog.duration, 10*60
            assert worklog.body.blank?
          end
          should "not send any emails" do
            assert_emails 0
            assert_equal 1, @task.work_logs.size, 'task must have only one work log'
          end
        end
        context "without time spend" do
          setup do
            @parameters.merge!(:work_log=>{ })
            assert_equal 0, @task.work_logs.size, 'must not have worklogs before update'
            post(:update, @parameters)
            assert_response :redirect
          end
          should "not create any worklogs and not send any emails" do
            assert_emails 0
            assert_equal 0, @task.work_logs.size, 'must not have worklog'
          end
        end
      end
    end
  end
################################################
  context "a new task with a few users attached when creating" do
    setup do
      ActionMailer::Base.deliveries = []
      assert_emails 0
      @user_ids = @user.company.user_ids
      @parameters={
        :users => @user_ids,
        :assigned => @user_ids,
        :task => {
           :name => "test",
           :description => "Test description",
           :project_id => @user.company.projects.last.id
        }
      }
    end

    context "with a few todos" do
      should "create todos" do
        @parameters.merge!( {
            :todos=>[{"name"=>"First Todo", "completed_at"=>"", "creator_id"=>@user.id, "completed_by_user_id"=>""},
                     {"name"=>"Second Todo", "completed_at"=>"", "creator_id"=>@user.id, "completed_by_user_id"=>""}] })
         post(:create, @parameters)
         assert_equal ["First Todo", "Second Todo"], assigns(:task).todos.collect(&:name).sort
      end
    end

    context "with time spend" do
      setup do
        @parameters.merge!( { :work_log=>{:duration=>'10m', :started_at=>"02/02/2010 17:02" } })
      end

      context "with comment" do
        setup do
          @parameters.merge!({:comment=> "Test comment"})
          #this context not have other contexts, so make post here
          post(:create, @parameters)
          @new_task=assigns(:task)
          assert_redirected_to "/tasks/list"
        end

        should "create work log with type TASK_CREATED, without time spend, with task description as a body  and not send it" do
          assert @new_task.work_logs.exists?
          work_log= @new_task.work_logs.find_by_log_type( EventLog::TASK_CREATED )
          assert_equal work_log.duration, 0
          assert work_log.body =~ /#{@new_task.description}/
        end

        should "create work log with type TASK_WORK_ADDED, with time, comment as a body  and send it" do
          assert @new_task.work_logs.exists?
          work_log= @new_task.work_logs.find_by_log_type( EventLog::TASK_WORK_ADDED )
          assert_equal work_log.duration,  60*10  # 10 minutes
          assert work_log.comment?
          assert work_log.body =~ /#{@parameters[:comment]}/
        end

        should "send one email to each user,  with comment" do
          assert_emails @new_task.users.length
        end
      end
      context "without comment" do
        setup do
          @parameters.merge!({:comment=> ""})
          #this context not have other contexts, so make post here
          post(:create, @parameters)
          @new_task=assigns(:task)
          assert_redirected_to "/tasks/list"
        end

        should "create work log with type TASK_CREATED, without time spend, with task description as a body and send it" do
          assert @new_task.work_logs.exists?
          work_log= @new_task.work_logs.find_by_log_type( EventLog::TASK_CREATED )
          assert_equal work_log.duration, 0
          assert work_log.body =~ /#{@new_task.description}/
        end

        should "create work log with type TASK_WORK_ADDED, with time spend, without body and not send it" do
          assert @new_task.work_logs.exists?
          work_log= @new_task.work_logs.find_by_log_type( EventLog::TASK_WORK_ADDED )
          assert_equal work_log.duration,  60*10  # 10 minutes
          assert ! work_log.comment?
          assert work_log.body.blank?
        end

        should "send only one email to each user, with task description" do
          assert_emails  @new_task.users.length
        end
      end
    end
    context "without time spend" do
      setup do
         @parameters.merge!( { :work_log=>{} })
      end

      context "with comment" do
        setup do
          @parameters.merge!({:comment=> "Test comment"})
          #this context not have other contexts, so make post here
          post(:create, @parameters)
          @new_task=assigns(:task)
          assert_redirected_to "/tasks/list"
        end

        should "create work log with type TASK_CREATED, without time spend, with task description as a body and not send it" do
          assert @new_task.work_logs.exists?
          work_log= @new_task.work_logs.find_by_log_type( EventLog::TASK_CREATED )
          assert_equal work_log.duration, 0
          assert work_log.body =~ /#{@new_task.description}/
        end

        should "create work log with type TASK_COMMENT, without time spend, comment as a body and send it" do
          assert @new_task.work_logs.exists?
          work_log= @new_task.work_logs.find_by_log_type( EventLog::TASK_COMMENT )
          assert_not_nil work_log
          assert_equal work_log.duration, 0
          assert work_log.comment?
          assert work_log.body =~ /#{@parameters[:comment]}/
        end

         should "send one email to each user, with comment" do
          assert_emails @new_task.users.length
        end
      end
      context "without comment" do
        setup do
          @parameters.merge!({:comment=> ""})
          #this context not have other contexts, so make post here
          post(:create, @parameters)
          @new_task=assigns(:task)
          assert_redirected_to "/tasks/list"
        end

        should "create work log with type TASK_CREATED, without time spend, with task description as a body and send it" do
          assert @new_task.work_logs.exists?
          work_log= @new_task.work_logs.find_by_log_type( EventLog::TASK_CREATED )
          assert_equal work_log.duration, 0
          assert work_log.body =~ /#{@new_task.description}/
        end

        should "send only one email to each user, with task description" do
          assert_emails  @new_task.users.length
        end
      end
    end
  end

####################################################################

  context "a normal task" do
    setup do
      @task = Task.first
    end

    should "render create ok" do
      customer = @task.company.customers.last
      project = customer.projects.first

      post(:create, :id => @task.id, :task => {
             :project_id => project.id,
             :customer_attributes => { customer.id => "1" } })

      assert_response :success
    end

    should "render auto_complete_for_dependency_targets" do
      get :auto_complete_for_dependency_targets, :term =>  @task.name

      assert_response :success
      assert_equal Task.search(@user,[@task.name]), assigns("tasks")
    end

    should "render add_client" do
      get :add_client, :id => @task.id, :client_id => @task.company.customers.first.id
      assert_response :success
    end

    context "with an auto add user" do
      setup do
        @customer = @task.company.customers.first
        project = @customer.projects.make(:company => @task.company,
                                          :users => [ @user ])
        @user = @customer.users.make(:company => @task.company,
                                 :auto_add_to_customer_tasks => 1)
      end

      should "return auto add users for add_users_for_client" do
        get :add_users_for_client, :id => @task.id, :client_id => @customer.id
        assert_response :success
        assert @response.body.index(@user.name)
      end

      should "return auto add users for add_users_for_client with project_id" do
        get :add_users_for_client, :project_id => @customer.projects.first.id
        assert_response :success
        assert @response.body.index(@user.name)
      end
    end
  end
 end
end
