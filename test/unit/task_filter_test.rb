require "test_helper"

class TaskFilterTest < ActiveSupport::TestCase

  should have_many(:qualifiers)
  should belong_to(:user)
  should validate_presence_of(:user)
  should validate_presence_of(:name)
  should have_many(:keywords).dependent(:destroy)

  context "TaskFilter.system_filter" do
    setup do
      @user = User.make
    end

    should "create and save a filter in system filter if none exists" do
      assert_nil TaskFilter.where(:user_id => @user.id, :system => true).first

      filter = TaskFilter.system_filter(@user)
      found = TaskFilter.where(:user_id => @user.id, :system => true).first
      assert_not_nil found
      assert_equal filter, found
    end

    should "return existing filter from system filter if one does exist" do
      filter = TaskFilter.make_unsaved(:user_id => @user.id, :system => true)
      filter.save!
      found = TaskFilter.system_filter(@user)
      assert_equal filter, found
    end
  end


  should "set keywords using keywords_attributes=" do
    filter = TaskFilter.make_unsaved
    assert filter.keywords.empty?

    filter.keywords_attributes = [ { :word=>"keyword1"}, {:word=>"keyword2"} ]
    assert_equal "keyword1", filter.keywords[0].word
    assert_equal "keyword2", filter.keywords[1].word
  end

  # Checks task filter includes the given class in conditions
  def self.should_filter_on(klass, column_name = nil)
    column_name ||= "#{ klass.name.downcase }_id"

    should "setup filter ids for #{ klass.name } on #{ column_name }" do
      qualifiers = klass.all
      assert qualifiers.any?
      ids = qualifiers.map { |o| o.id }

      filter = TaskFilter.make_unsaved
      qualifiers.each { |q| filter.qualifiers.build(:qualifiable => q) }
      conditions = filter.conditions
      assert_not_nil conditions.index("#{ column_name } in (#{ ids.join(",") })")
    end
  end

  should_filter_on Project
  should_filter_on Milestone
  should_filter_on Customer, "projects.customer_id"
  should_filter_on Customer, "task_customers.customer_id"
  should_filter_on User, "task_users.user_id"
  should_filter_on Tag, "task_tags.tag_id"

  context "a normal company" do
    setup do
      @company = Company.last
      @company.create_default_properties
      Status.create_default_statuses(@company)
    end

    should "filter on custom attributes separately" do
      type = @company.type_property
      priority = @company.properties.detect{ |p| p.name == "Priority"}
      assert_not_nil type
      assert_not_nil priority

      filter = TaskFilter.make_unsaved
      filter.qualifiers.build(:qualifiable => type.property_values[0])
      filter.qualifiers.build(:qualifiable => type.property_values[1])
      filter.qualifiers.build(:qualifiable => priority.property_values[0])
      actual = filter.conditions

      expected = "task_property_values.property_value_id IN (#{ type.property_values[0].id }, #{ type.property_values[1].id })"
      assert_not_nil actual.index(expected)

      expected = "task_property_values.property_value_id IN (#{ priority.property_values[0].id })"
      assert_not_nil actual.index(expected)
    end

    should "filter on status" do
      s1 = @company.statuses[0]
      s2 = @company.statuses[3]

      filter = TaskFilter.make_unsaved(:company => @company)
      filter.qualifiers.build(:qualifiable => s1)
      filter.qualifiers.build(:qualifiable => s2)
      actual = filter.conditions

      # using position of status in list as a way to link to old
      # status for now
      expected = "tasks.status in (0,3)"
      assert_not_nil actual.index(expected)
    end

    should "filter on keywords" do
      filter = TaskFilter.make_unsaved
      filter.keywords.build(:word => "keyword1")
      filter.keywords.build(:word => "keyword2")

      conditions = filter.conditions

      kw1 = Task.connection.quote_string("%keyword1%")
      kw2 = Task.connection.quote_string("%keyword2%")
      sql = (0...2).map { "coalesce((lower(tasks.name) like ? or lower(tasks.description) like ?),0)" }.join(" or ")
      params = [ kw1, kw1, kw2, kw2 ]
      expected = Task.send(:sanitize_sql_array, [ sql ] + params)
      assert_not_nil conditions.index(expected)
    end

    should "escape keywords" do
      filter = TaskFilter.make_unsaved
      filter.keywords.build(:word => "brad's")

      conditions = filter.conditions
      escaped = Task.connection.quote_string("%brad's%")
      # postgres quote || mysql quote
      match = conditions.index("''") || conditions.index("\'")
      assert_not_nil match
    end

    should "filter on time ranges" do
      range = TimeRange.make(:start => "Date.today", :end => "Date.tomorrow")
      filter = TaskFilter.make_unsaved
      filter.qualifiers.build(:qualifiable => range, :qualifiable_column => "due_date")

      conditions = filter.conditions
      escaped = Task.connection.quote_column_name("due_date")
      expected = "(tasks.#{ escaped } >= '#{ Date.today.to_formatted_s(:db) }'"
      expected += " and tasks.#{ escaped} < '#{ Date.tomorrow.to_formatted_s(:db) }')"

      assert_not_nil conditions.index(expected)
    end

    should "escape qualifiable names for time ranges" do
      range = TimeRange.make(:start => "Date.today", :end => "Date.tomorrow")
      filter = TaskFilter.make_unsaved
      filter.qualifiers.build(:qualifiable => range, :qualifiable_column => ";delete * from users;")

      conditions = filter.conditions
      escaped = Task.connection.quote_column_name(";delete * from users;")
      assert_not_nil conditions.index(escaped)
    end

    should "filter on read/unread tasks" do
      filter = TaskFilter.make(:unread_only => true)
      user = filter.user
      conditions = filter.conditions
      expected = "((task_users.unread = ? and task_users.user_id = #{ user.id })"
      expected = TaskFilter.send(:sanitize_sql_array, [ expected, true ])

      assert_not_nil conditions.index(expected)
    end

    should "change cache key every request when unread_only true" do
      filter = TaskFilter.make(:unread_only => true)
      assert_not_equal filter.cache_key, filter.cache_key
    end

    should "not change cache key every request when unread_only false" do
      filter = TaskFilter.make(:unread_only => false)
      assert_equal filter.cache_key, filter.cache_key
    end

  end

  context "a company with projects, tasks, etc" do
    setup do
      @company = Company.make
      customer = Customer.make(:company => @company)
      @user = User.make(:customer => customer, :company => @company)
      @project =  project_with_some_tasks(@user)

      @task = @project.tasks.first
      assert @task.users.include?(@user)
      assert @project.users.include?(@user)

      @filter = TaskFilter.new(:user => @user, :name => "Some Filter")
      @filter.qualifiers.build(:qualifiable => @project)
    end

    should "TaskFilter#update_filter should update filter by params" do
      @filter.save!
      @filter.keywords.create(:word=>'keyword')
      params = {"qualifiers_attributes"=>[{"qualifiable_id"=>@company.statuses.first.id, "qualifiable_type"=>"Status", "qualifiable_column"=>"", "reversed"=>"false"}], "keywords_attributes"=>[{"word"=>"key", "reversed"=>"false"}], "unread_only"=>"false"}
      @filter.update_filter(params)
      @filter.reload
      assert_equal @filter.keywords.first.word, "key"
      assert_equal @filter.keywords.count, 1
      assert_equal @filter.qualifiers.count, 1
      assert_equal @filter.qualifiers.first.qualifiable, @company.statuses.first
    end

    should "count unassigned tasks in display_count" do
      initial_count = @filter.display_count(@user)
      @task.task_owners.clear
      @task.save!

      assert_equal initial_count + 1, @filter.display_count(@user, true)
    end

    should "count unread tasks in display_count" do
      initial_count = @filter.display_count(@user)
      task_owner = @task.task_owners.detect { |to| to.user == @user }
      assert_not_nil task_owner
      task_owner.update_attribute(:unread, true)

      assert_equal initial_count + 1, @filter.display_count(@user, true)
    end

    should "include tasks linked to a customer when filtering on customer" do
      @filter.qualifiers.clear
      other_customer = Customer.make(:company => @company, :name => "Test name")
      @filter.qualifiers.build(:qualifiable => other_customer)

      conditions = @filter.conditions
      expected = "task_customers.customer_id in (#{ other_customer.id })"

      assert conditions.index(expected)
    end
    context ",  filter for jqGrid" do
      should "sort tasks by id asc" do
        params={ :sord=>'asc',:sidx=>'id'}
        assert_equal @filter.tasks_for_jqgrid(params).all, @filter.tasks
      end
      should "sort tasks by id desc" do
        params={ :sord=>'desc',:sidx=>'id'}
        assert_equal @filter.tasks_for_jqgrid(params).all, @filter.tasks.reverse
      end
    end
    context ", filter for Full Calendar" do
      setup do
        @t1=@filter.tasks[0]
        @t2=@filter.tasks[1]
        @t1.due_at=Time.now+1.day
        @t2.due_at=Time.now+5.day
        @t1.save!
        @t2.save!
      end
      should "return tasks by date" do
        params= {:start=>(Time.now - 2.day).to_i, :end=> (Time.now + 2.day).to_i}
        assert_equal @filter.tasks_for_fullcalendar(params), [@t1]
      end
      should "return tasks by another date" do
        params= {:start=>(Time.now + 2.day).to_i, :end=> (Time.now + 7.day).to_i}
        assert_equal @filter.tasks_for_fullcalendar(params), [@t2]
      end
      context "when the task has a milestone and the milestone's due_date not nil" do
        setup do
          @t2.milestone= Milestone.make(:project=> @t2.project, :company=> @t2.company)
          @t2.milestone.due_at= @t2.due_at
          @params= {:start=>(Time.now + 2.day).to_i, :end=> (Time.now + 7.day).to_i}
        end
         context "and tast has due_at," do
           should "be task in the calendar" do
              assert_equal [@t2], @filter.tasks_for_fullcalendar(@params)
           end
         end
         context "and task has not due_at," do
           should "be task in the calendar" do
              @t2.due_at=nil
              @t2.save!
              assert_equal [@t2], @filter.tasks_for_fullcalendar(@params)
           end
         end
      end
    end
  end
end







# == Schema Information
#
# Table name: task_filters
#
#  id                 :integer(4)      not null, primary key
#  name               :string(255)
#  company_id         :integer(4)
#  user_id            :integer(4)
#  shared             :boolean(1)
#  created_at         :datetime
#  updated_at         :datetime
#  system             :boolean(1)      default(FALSE)
#  unread_only        :boolean(1)      default(FALSE)
#  recent_for_user_id :integer(4)
#
# Indexes
#
#  fk_task_filters_company_id  (company_id)
#  fk_task_filters_user_id     (user_id)
#

