require 'test_helper'

class TasksControllerTest < ActionController::TestCase

  def setup
    @user = User.make(:admin)
    sign_in @user
    @user.company.create_default_statuses

    @project = project_with_some_tasks(@user)
  end

  context "on POST change_task_weight" do
    setup do
      @task_current = TaskRecord.make(:weight_adjustment => 30, :project => @project, :company => @user.company)
      @task_prev = TaskRecord.make(:weight_adjustment => 50, :project => @project, :company => @user.company)
      TaskUser.new(:user_id => @user.id, :task_id => @task_current.id).save
      TaskUser.new(:user_id => @user.id, :task_id => @task_prev.id).save
    end
    should "change tasks weight if we have current and prev tasks" do
      post(:change_task_weight, :moved => @task_current.id, :prev => @task_prev.id)
      task = TaskRecord.find(@task_current.id)
      assert task.weight < @task_prev.weight
    end
  end

  context "on GET nextTasks" do
    setup do
      TaskRecord.all.each do |task|
        TaskUser.new(:user_id => @user.id, :task_id => task.id).save
      end
      get :nextTasks, :count => 5
    end
    should respond_with(:success)
    should respond_with_content_type('application/json')
  end

  should "render :success on /edit" do
    task = @user.tasks.first

    get :edit, :id => task.task_num
    assert_response :success
  end

  should "find task by task num on /edit" do
    task = @user.tasks.first
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

  should "render :success on /index" do
    company = @user.company

    # need to create a task to ensure the task partials get rendered
    task = TaskRecord.new(:name => "Test", :project_id => company.projects.last.id)
    task.company = company
    task.save!

    get :index
    assert_response :success
    assert TaskFilter.system_filter(@user).tasks.include?(task)
  end

  should "render form ok when failing update on /update" do
    task = @user.tasks.first
    # post something that will cause a validation to fail
    post(:update, :id => task.id, :task => { :name => "" })

    assert_response :success
    assert flash[:error] == "Name can't be blank"
  end

  should "render error message on name when name not presented on /update" do
    task = @user.tasks.first
    post(:update, :id => task.id, :task => { :name => "" })
    assert assigns['task'].errors[:name].any?
  end

  should "render error message on project when project not presented on /update" do
    task = @user.tasks.first
    post(:update, :id => task.id, :task => { :project_id =>""})
    assert assigns['task'].errors[:project_id].any?
  end

  should "render JSON error message when validation failed on /update?format=js" do
    task = @user.tasks.first
    post(:update, :format => 'js', :id => task.id, :task => { :project_id =>""})
    assert assigns['task'].errors[:project_id].any?
    json_response = ActiveSupport::JSON.decode(@response.body)
    assert_equal({"messages"=>["Project can't be blank"], "status"=>"error"}, json_response)
  end

  context "a task with a few users attached" do
    setup do
      ActionMailer::Base.deliveries = []
      @task = @user.tasks.first
      @task.users << User.make(:company => @user.company)
      @task.status = 0
      @task.save!
      assert_emails 0
    end
    teardown do
      @task.work_logs.destroy_all
    end

    should "render JSON when adding a comment and attachment with Ajax" do
      file = fixture_file_upload('/files/rails.png', 'image/png')

      # https://github.com/rails/rails/issues/799
      class << file
        attr_reader :tempfile
      end

      post(:update, :id => @task.id, :task => { }, :format => "js",
           :users => @task.user_ids,
           :comment => "a test comment",
           :tmp_files => [ file ])

      json_response = ActiveSupport::JSON.decode(@response.body)
      attachments = @task.reload.attachments
      assert_equal 1, attachments.size
      assert_equal "success", json_response["status"]
      assert_equal @task.task_num, json_response["tasknum"]
      #check attachment
      uri = attachments.first.uri
      assert_equal true, File.exist?("#{Rails.root}/store/#{@user.company.id}/#{uri}_original.png")
      assert_equal true, File.exist?("#{Rails.root}/store/#{@user.company.id}/#{uri}_thumbnail.png")
      @task.attachments.destroy_all
    end

    should "prevent duplication of files when adding the same attachment to two tasks" do

      file = fixture_file_upload('/files/rails.png', 'image/png')
      # https://github.com/rails/rails/issues/799
      class << file
        attr_reader :tempfile
      end

      post(:update, :id => @task.id, :task => { }, :format => "js",
           :users => @task.user_ids,
           :tmp_files => [ file ]
          )

      size_before = Dir.entries("#{Rails.root}/store/#{@user.company.id}").size

      second_task = TaskRecord.last
      second_task.users << second_task.company.users
      second_task.status = 0
      second_task.save!

      file = fixture_file_upload('/files/rails.png', 'image/png')
      # https://github.com/rails/rails/issues/799
      class << file
        attr_reader :tempfile
      end

      post(:update, :id => second_task.id, :task => { }, :format => "js",
           :users => second_task.user_ids,
           :tmp_files => [ file ]
          )

      # total files cound should keep unchanged
      assert_equal size_before, Dir.entries("#{Rails.root}/store/#{@user.company.id}").size
      second_task.attachments.destroy_all
    end

    should "get 'Unauthorized' when adding a comment and session has timed out" do
      sign_out @user
      post(:update, :id => @task.id, :task => { }, :format => "js",
           :users => @task.user_ids,
           :comment => "a test comment")
      assert_equal "Unauthorized", @response.message
    end

    should "send emails to each user when adding a comment" do
      post(:update, :id => @task.id, :task => { },
           :users => @task.user_ids,
           :comment => "a test comment")
      assert_emails @task.users.length
      assert_response :redirect
    end

    should "send unescaped html in email" do
      # TODO DRY
      @task.name = "<strong>name</strong> ; <script> alert('XSS');</script>"
      @task.description = "<strong>description</strong> ; <script> alert('XSS');</script>"
      comment_html = "<strong>comment</strong> ; <script> alert('XSS');</script>"
      @task.save!
      post(:update, :id => @task.id, :task => { },
           :users => @task.user_ids,
           :comment => comment_html)
      @task.reload
      assert_emails @task.users.length
      assert_response :redirect
      mail = ActionMailer::Base.deliveries.first
      mail_body = mail.body.to_s
      %w/ name description comment /.each do |field|
        regexp = Regexp.new(Regexp.escape("<strong>#{field}</strong> ; <script> alert('XSS');</script>"))
        assert_match regexp, mail_body
      end
    end

    should "update group when user dragging task on task grid" do
      # custom property
      property = Property.make(:company => @user.company)
      property_value = PropertyValue.make(:property => property)
      TaskPropertyValue.make(:task_id => @task.id, :property => property, :property_value => property_value)

      post :set_group, :id => @task.task_num, :group => property.name, :value => property_value.value
      tpv = @task.task_property_values.reload.detect { |tpv| tpv.property_id == property.id }
      assert_equal property_value.id, tpv.property_value_id

      property_value2 = PropertyValue.make(:property => property)
      post :set_group, :id => @task.task_num, :group => property.name, :value => property_value2.value
      tpv = @task.task_property_values.reload.detect { |tpv| tpv.property_id == property.id }
      assert_equal property_value2.id, tpv.property_value_id

      #milestone
      milestone = Milestone.make(:project => @task.project, :company => @user.company)
      post :set_group, :id => @task.task_num, :group => 'milestone', :value => "#{milestone.project.name}/#{milestone.name}"
      assert_equal milestone.id, @task.reload.milestone_id

      #resolution
      resolution_arr = @task.statuses_for_select_list.clone.delete_if{|x| x[1] == @task.status}.rand
      post :set_group, :id => @task.task_num, :group => "resolution", :value => resolution_arr[0]
      assert_equal resolution_arr[1], @task.reload.status
    end

    context "one of task's watched attributes changed," do
      setup do
        @parameters = {:id => @task.id, :task => { :name => "ababa-galamaga"}, :users => @task.user_ids, :assigned => @task.owner_ids}
      end
      context "with comment added," do
        setup do
          @parameters.merge!(:comment =>'Just a comment')
        end
        context "with time spend" do
          setup do
            @parameters.merge!(:work_log => { :duration => '10m',:started_at => Time.now.utc.to_s})
            post(:update,@parameters)
            assert_response :redirect
          end
          should "create work log with type according to changes, with (changes+comment) as a body, without time and send it" do
            worklog = @task.work_logs.detect {|wl| wl.comment? }
            assert_not_nil worklog
            assert_equal worklog.duration, 10
            assert @task.event_logs.last.body =~ /name/i, "work log body must include changes "
            assert worklog.body =~ /#{@parameters[:comment]}/, "work log body must include comment"
          end
          should "send one email to each user" do
            assert_emails  @task.users.length
            assert_equal @task.work_logs.count, 1
          end
        end
        context "without time spend" do
          setup do
            @parameters.merge!(:work_log => {})
            post(:update,@parameters)
            assert_response :redirect
          end
          should "create work log with type according to changes, with (changes + comment) as a body, without time and send it" do
            worklog = @task.work_logs.detect {|wl| wl.comment? }
            assert_not_nil worklog
            assert_equal worklog.duration, 0
            assert @task.event_logs.last.body =~ /name/i, "work log body must include changes "
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
          @parameters.merge!(:comment => '')
        end
        context "with time spend" do
          setup do
            @parameters.merge!(:work_log => { :duration => '10m',:started_at => Time.now.utc.to_s})
            post(:update,@parameters)
            assert_response :redirect
          end
          should "create work log with type according to changes, with changes as a body, without time and not send it" do
            assert @task.event_logs.last.body =~ /name/i, "work log body must include changes "
          end
          should "create work log with type TASK_WORK_ADDED, without any comment, with time spend and not send it" do
            worklog = @task.work_logs.detect {|wl| wl.worktime? }
            assert_not_nil worklog
            assert_equal worklog.duration, 10
            assert !(worklog.body =~ /name/i), "work log body must not include changes"
          end
          should "not send any emails" do
            assert_emails 0
            assert_equal @task.work_logs.count, 1
          end
        end
        context "without time spend" do
          setup do
            @parameters.merge!(:work_log => {})
            post(:update,@parameters)
            assert_response :redirect
          end
          should "create event log, no worklogs" do
            assert @task.event_logs.last.body =~ /name/i, "work log body must include changes "
            assert_equal @task.work_logs.count, 0
          end
          should "not send any emails" do
            assert_emails 0
            assert_equal @task.work_logs.count, 0
          end
        end
      end
    end
    context "without changes to task's watched attributes" do
      setup do
        @parameters = {:id => @task.id, :assigned => @task.user_ids, :task => {}, :users => @task.user_ids}
      end
      context "with comment added," do
        setup do
          @parameters.merge!(:comment => 'Just a comment')
        end
        context "with time spend" do
          setup do
            @parameters.merge!(:work_log => {:duration => '10m',:started_at => Time.now.utc.to_s })
            assert_equal 0, @task.work_logs.count, 'before call update task don\'t have worklogs'
            post(:update, @parameters)
            assert_response :redirect
          end
          should "create work log with type TASK_WORK_ADDED, with comment as a body, with time spend and send it" do
            worklog = @task.work_logs.detect {|wl| wl.worktime? }
            assert_not_nil worklog
            assert_equal worklog.duration, 10
            assert worklog.body =~ /#{@parameters[:comment]}/, "work log body must include comment"
          end
          should "send only one email to each user and create only one work log" do
            assert_emails @task.users.length
            assert_equal 1, @task.work_logs.count,  'number of work logs'
          end
        end
        context "without time spend" do
          setup do
            @parameters.merge!(:work_log => {})
            post(:update, @parameters)
            assert_response :redirect
          end
          should "create work log with type TASK_COMMENT, with comment as a body and send it" do
            worklog = @task.work_logs.detect {|wl| wl.comment? }
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
      context "reopen closed task on commenting" do
        setup do
          @parameters.merge!(:comment => 'Just a comment')
        end

        should "not reopen task when comment on closing" do
          @parameters[:task][:status] = 1
          post(:update, @parameters)
          assert_equal @task.reload.status, 1
        end

        should "reopen task when comment on closed task" do
          @task.update_attributes(:status => 1)
          post(:update, @parameters)
          assert_equal @task.reload.status, TaskRecord.status_types.index("Open")
        end
      end
      context "without comment," do
        setup do
          @parameters.merge!( :comment => nil)
        end
        context "with time spend" do
          setup do
            @parameters.merge!(:work_log => {:duration => '10m',:started_at => Time.now.utc.to_s })
            post(:update, @parameters)
            assert_response :redirect
          end
          should "create work log with type TASK_WORK_ADDED, without body, and not send it" do
            worklog = @task.work_logs.detect {|wl| wl.worktime? }
            assert_not_nil worklog
            assert_equal worklog.duration, 10
            assert worklog.body.blank?
          end
          should "not send any emails" do
            assert_emails 0
            assert_equal 1, @task.work_logs.size, 'task must have only one work log'
          end
        end
        context "without time spend" do
          setup do
            @parameters.merge!(:work_log => {})
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
      @parameters = {
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
            :todos => [{"name"=>"First Todo", "completed_at"=>"", "creator_id"=>@user.id, "completed_by_user_id"=>""},
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
          @parameters.merge!({:comment => "Test comment"})
          #this context not have other contexts, so make post here
          post(:create, @parameters)
          @new_task=assigns(:task)
          assert_redirected_to tasks_path
        end

        should "create work log with type TASK_CREATED, without time spend, with task description as a body  and not send it" do
          assert @new_task.work_logs.exists?
          work_log = @new_task.work_logs.detect {|wl| wl.event_log.event_type == EventLog::TASK_CREATED }
          assert_equal work_log.duration, 0
          assert work_log.body =~ /#{@new_task.description}/
        end

        should "create work log with type TASK_WORK_ADDED, with time, comment as a body  and send it" do
          assert @new_task.work_logs.exists?
          work_log = @new_task.work_logs.detect {|wl| wl.worktime? }
          assert_equal work_log.duration,  10  # 10 minutes
          assert work_log.comment?
          assert work_log.body =~ /#{@parameters[:comment]}/
        end

        should "send one email to each user,  with comment" do
          assert_emails @new_task.users.length
        end
      end
      context "without comment" do
        setup do
          @parameters.merge!({:comment => ""})
          #this context not have other contexts, so make post here
          post(:create, @parameters)
          @new_task = assigns(:task)
          assert_redirected_to tasks_path
        end

        should "create work log with type TASK_CREATED, without time spend, with task description as a body and send it" do
          assert @new_task.work_logs.exists?
          work_log = @new_task.work_logs.detect {|wl| wl.event_log.event_type == EventLog::TASK_CREATED }
          assert_equal work_log.duration, 0
          assert work_log.body =~ /#{@new_task.description}/
        end

        should "create work log with type TASK_WORK_ADDED, with time spend, without body and not send it" do
          assert @new_task.work_logs.exists?
          work_log = @new_task.work_logs.detect {|wl| wl.worktime? }
          assert_equal work_log.duration,  10  # 10 minutes
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
         @parameters.merge!( { :work_log => {} })
      end

      context "with comment" do
        setup do
          @parameters.merge!({:comment => "Test comment"})
          #this context not have other contexts, so make post here
          post(:create, @parameters)
          @new_task = assigns(:task)
          assert_redirected_to tasks_path
        end

        should "create work log with type TASK_CREATED, without time spend, with task description as a body and not send it" do
          assert @new_task.work_logs.exists?
          work_log = @new_task.work_logs.detect {|wl| wl.event_log.event_type == EventLog::TASK_CREATED }
          assert_equal work_log.duration, 0
          assert work_log.body =~ /#{@new_task.description}/
        end

        should "create work log with type TASK_COMMENT, without time spend, comment as a body and send it" do
          assert @new_task.work_logs.exists?
          work_log = @new_task.work_logs.detect {|wl| wl.event_log.event_type == EventLog::TASK_COMMENT}
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
          @parameters.merge!({:comment => ""})
          #this context not have other contexts, so make post here
          post(:create, @parameters)
          @new_task = assigns(:task)
          assert_redirected_to tasks_path
        end

        should "create work log with type TASK_CREATED, without time spend, with task description as a body and send it" do
          assert @new_task.work_logs.exists?
          work_log = @new_task.work_logs.detect {|wl| wl.event_log.event_type == EventLog::TASK_CREATED }
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
      @task = @user.tasks.first
    end

    should "render auto_complete_for_dependency_targets" do
      get :auto_complete_for_dependency_targets, :term =>  @task.name

      assert_response :success
      assert_equal TaskRecord.search(@user,[@task.name]), assigns("tasks")
    end

    should "render get_customer" do
      get :get_customer, :id => @task.id, :customer_id => @task.company.customers.first.id
      assert_response :success
    end

    context "with an auto add user" do
      setup do
        @customer = @task.company.customers.first
        project = @customer.projects.make(:company => @task.company,
                                          :users => [ @user ])
        @user = @customer.users.make(:company => @task.company,
                                 :auto_add_to_customer_tasks => 1)
        project.users << @user
      end

      should "return auto add users for get_default_watchers_for_customer" do
        get :get_default_watchers_for_customer, :id => @task.id, :customer_id => @customer.id
        assert_response :success
        assert @response.body.index(@user.name)
      end

      should "return auto add users for get_default_watchers with project_id" do
        get :get_default_watchers, :project_id => @customer.projects.first.id
        assert_response :success
        assert @response.body.index(@user.name)
      end
    end
  end


  context "test billable" do
    setup do
      @project = Project.make(:company => @user.company)
      @project.users << @user

      @one = Service.create :name => "mobile", :description => "mobile service", :company => @user.company
      @two = Service.create :name => "web", :description => "web service", :company => @user.company
      @three = Service.create :name => "car", :description => "car service", :company => @user.company
      @four = Service.create :name => "hotel", :description => "hotel service", :company => @user.company
    end

    should "task of Project.supressBilling = true be unbillable" do
      @project.update_attributes(:suppressBilling => true)
      get :billable, :project_id => @project.id
      assert JSON.parse(response.body)["billable"] == false
    end

    should "task of service = nil be billable" do
      @project.update_attributes(:suppressBilling => false)
      get :billable, :project_id => @project.id
      assert JSON.parse(response.body)["billable"] == true
    end

    should "quoted task should be unbillable" do
      get :billable, :project_id => @project.id, :service_id => -1
      assert JSON.parse(response.body)["billable"] == false
    end

    context "SLAs" do
      setup do
        @project.update_attributes(:suppressBilling => false)

        @customer_1 = Customer.make(:company => @user.company)
        @customer_1.service_level_agreements.create :billable => false, :service => @one
        @customer_1.service_level_agreements.create :billable => false, :service => @two
        @customer_1.service_level_agreements.create :billable => false, :service => @three

        @customer_2 = Customer.make(:company => @user.company)
        @customer_2.service_level_agreements.create :billable => false, :service => @one
        @customer_2.service_level_agreements.create :billable => true, :service => @two
        @customer_2.service_level_agreements.create :billable => false, :service => @three
      end

      should "task of one billable SLA should be billable" do
        get :billable, :project_id => @project.id, :customer_ids => [@customer_1.id, @customer_2.id].join(","), :service_id => @two.id
        assert JSON.parse(response.body)["billable"] == true
      end

      should "task of all unbillable SLAs should be unbillable" do
        get :billable, :project_id => @project.id, :customer_ids => [@customer_1.id, @customer_2.id].join(","), :service_id => @one.id
        assert JSON.parse(response.body)["billable"] == false
      end

      should "task of zero SLA should be unbillable" do
        get :billable, :project_id => @project.id, :customer_ids => [@customer_1.id, @customer_2.id].join(","), :service_id => @four.id
        assert JSON.parse(response.body)["billable"] == false
      end
    end
  end

  context "test acccess rights" do
    setup do
      @user = User.make
      @project = Project.make(:company => @user.company)

      perm = ProjectPermission.new(:project => @project, :user => @user)
      perm.remove('all')
      perm.set('comment')
      perm.set('see_unwatched')
      perm.save!

      sign_in @user
    end

    should "a user with only comment rights be able to comment on task" do
      task = TaskRecord.make(:company => @project.company, :project => @project, :name => "initial name")

      assert !@user.can?(@project, 'edit')
      assert @user.can?(@project, 'comment')

      put :update, :id => task.id, :task => {:name => "update name"}, :comment => "test comment"

      assert task.reload.name == "initial name"
      assert task.reload.work_logs.last.body == "test comment"
      error_msg = I18n.t('flash.notice.model_updated', model: TaskRecord.model_name.human)
      assert flash[:success] =~ Regexp.new(error_msg)
    end
  end

  context "task planning" do
    should "admin be able to access task planning" do
      @user = User.make(:admin)
      sign_in @user
      get :planning
      assert_response :success
    end

    should "non-admin be unable to access task planning" do
      @user = User.make
      sign_in @user
      get :planning
      assert_response :redirect
    end
  end

end

