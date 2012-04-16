require "test_helper"

class TaskFiltersControllerTest < ActionController::TestCase
  def assert_json(args)
    assert_not_nil JSON.parse(@response.body).detect do |hash|
      res = true
      args.each_pair{|key, value| res = false unless hash[key] == value  }
      res
    end
  end

  signed_in_admin_context do
    setup do
      @request.with_subdomain('cit')
      project = @user.company.projects.first
      @user.projects << project
      @user.save!

      milestone = Milestone.make(:project => project, :company => @user.company)
      @task = Task.make(:users => [ @user ], :company => @user.company,
                        :project => project, :milestone => milestone)
      assert_not_nil @task
    end

    should "return nothing with an empty search" do
      get :search
      body = @response.body.gsub(/\s/, "")
      assert_equal "", body
    end

    should "be able to search by task project" do
      get :search, :term => @task.project.name
      assert_json({
                   "id" => "task_filter[qualifiers_attributes][][qualifiable_id]",
                   "idval" => @task.project.id
                  })
    end

    should "be able to search by task customer" do
      get :search, :term => @task.project.customer.name
      assert_json({
                   "id" => "task_filter[qualifiers_attributes][][qualifiable_id]",
                   "idval" => @task.project.customer.id
                  })
    end


    should "be able to search by task milestone" do
      get :search, :term => @task.milestone.name
      assert_json({
                   "id" => "task_filter[qualifiers_attributes][][qualifiable_id]",
                   "idval" => @task.milestone.id}
                 )
    end

    should "be able to search by tags" do
      tag = Tag.make(:company => @user.company)
      get :search, :term => tag.name
      assert_json({
                   "id" => "task_filter[qualifiers_attributes][][qualifiable_id]",
                   "idval" => tag.id
                  })
    end

    should "be able to search by task status" do
      Status.create_default_statuses(@user.company)
      status = @user.company.statuses.rand
      get :search, :term => status.name
      assert_json({
                   "id" => "task_filter[qualifiers_attributes][][qualifiable_id]",
                   "idval" => status.id
                  })
    end

    should "be able to search by task user" do
      get :search, :term => @user.name
      assert_json({
                   "id" => "task_filter[qualifiers_attributes][][qualifiable_id]",
                   "idval" => @user.id
                  })
    end

    should "be able to search by keyword" do
      get :search, :term => "A keyword"
      assert_json({
                   "id" => "task_filter[keywords_attributes][][word]",
                   "idval" => "a keyword"
                  })
    end

    should "be able to search by read status" do
      get :search, :term => "unread"
      assert_json({
                    "id" => "task_filter[unread_only]",
                    "idval" => true
                   })
    end

    context "searching on time ranges" do
      setup do
        @time_range = TimeRange.make(:name => "today")
        get :search, :term => @time_range.name
      end

      should "should find time range by name" do
         assert_json({
                      "id" => "task_filter[qualifiers_attributes][][qualifiable_id]",
                      "idval" => @time_range.id
                     })
      end

      should "have due_at qualifiable_name" do
        assert_json({
                     "col" => "task_filter[qualifiers_attributes][][qualifiable_column]",
                      "colval" => "due_at"
                    })
      end

      should "have create_at qualifiable_name" do

           assert_json({
                        "col" => "task_filter[qualifiers_attributes][][qualifiable_column]",
                        "colval" => "created_at"
                       })
      end

      should "have updated_at qualifiable_name" do
          assert_json({
                       "col" => "task_filter[qualifiers_attributes][][qualifiable_column]",
                       "colval" => "updated_at"
                      })
      end
    end

    should "be able to search by task attributes" do
      property = @user.company.properties.first
      value = property.property_values.first
      assert_not_nil property
      assert_not_nil value

      get :search, :term => value.value
      assert_json({
                   "id" => "task_filter[qualifiers_attributes][][qualifiable_id]", "idval" => value.id
                  })
    end

    should "be able to render new" do
      get :new
      assert_response :success
    end

    context "when saving their current filter" do
      setup do
        filter = TaskFilter.system_filter(@user)
        filter.qualifiers.build(:qualifiable => @task.project)
        filter.keywords.build(:task_filter => filter, :company => @user.company,
                              :word => "keyword")
        filter.save!

        post(:create, :task_filter => { :name => "a new filter" })
        @filter = TaskFilter.where(:user_id => @user.id, :name => "a new filter").first
      end

      should "redirect to tasks" do
        assert_redirected_to "/tasks"
      end

      should "save to the db" do
        assert !@filter.new_record?
        assert_equal "a new filter", @filter.name
        assert_equal @user, @filter.user
        assert_equal @user.company, @filter.user.company
      end

      should "save qualifiers" do
        assert_equal 1, @filter.qualifiers.length
        assert_equal @task.project, @filter.qualifiers[0].qualifiable
      end

      should "save keywords" do
        assert_equal 1, @filter.keywords.length
        assert_equal "keyword", @filter.keywords[0].word
      end
    end


    context "with an existing saved filter" do
      setup do
        @filter = TaskFilter.new(:name => "a test filter", :user => @user)
        @filter.qualifiers.build(:qualifiable => @task.project)
        @filter.save!
      end

      should "be able to select their own filter" do
        get :select, :id => @filter.id
        assert_redirected_to "/tasks"
        system_filter = TaskFilter.system_filter(@user)

        assert_equal @filter.qualifiers.length, system_filter.qualifiers.length
        assert_equal @filter.keywords.length, system_filter.keywords.length
      end

      should "be able to delete their own filter" do
        delete :destroy, :id => @filter.id
        assert_redirected_to "/tasks"
        assert_nil TaskFilter.find_by_id(@filter.id)
      end

      should "get manage filter page" do
        get :manage
        assert_response :success
      end

      should "be able to hide own filter" do
        assert_equal true, @filter.show?(@user)
        get :toggle_status, :id => @filter
        assert_equal false, @filter.show?(@user)
      end

      should "be able to show own filter when it's hidden" do
        @filter.task_filter_users.where(:user_id => @user.id).first.destroy

        assert_equal false, @filter.show?(@user)
        get :toggle_status, :id => @filter
        assert_equal true, @filter.show?(@user)
      end

      context "which belongs to another user" do
        setup do
          user = (@user.company.users - [ @user ]).rand
          assert_not_nil user
          @filter.update_attribute(:user, user)
          @filter.task_filter_users.create(:user_id => user.id)
        end

        should "not be able to select another user's filter" do
          get :select, :id => @filter.id
          assert_redirected_to "/tasks"
          assert_not_equal @filter, session[:task_filter]
          assert flash[:error].index("access")
        end

        should "be able to select another user's shared filter" do
          @filter.update_attribute(:shared, true)
          get :select, :id => @filter.id
          assert_redirected_to "/tasks"
          system_filter = TaskFilter.system_filter(@user)
          assert_equal @filter.qualifiers.length, system_filter.qualifiers.length
          assert_equal @filter.keywords.length, system_filter.keywords.length
        end

        should "be able to delete another user's shared filter if they are admin" do
          @filter.update_attribute(:shared, true)

          assert @user.admin?
          delete :destroy, :id => @filter.id
          assert_redirected_to "/tasks"
          assert_nil TaskFilter.find_by_id(@filter.id)
        end

        should "not be able to delete another user's shared filter if they are not an admin" do
          @filter.update_attribute(:shared, true)

          @user.update_attribute(:admin, false)
          assert !@user.admin?
          delete :destroy, :id => @filter.id
          assert_redirected_to "/tasks"
          assert_not_nil TaskFilter.find_by_id(@filter.id)
        end

        should "be able to hide another user's shared filter " do
          @filter.update_attribute(:shared, true)

          assert_equal true, @filter.show?(@user)
          get :toggle_status, :id => @filter
          assert_equal false, @filter.show?(@user)
        end

        should "be able to show another user's shared filter when it's hidden" do
          @filter.task_filter_users.where(:user_id => @user.id).first.destroy
          @filter.update_attributes(:shared => true)

          assert_equal false, @filter.show?(@user)
          get :toggle_status, :id => @filter
          assert_equal true, @filter.show?(@user)
        end

      end
    end
  end
end
