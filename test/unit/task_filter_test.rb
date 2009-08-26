require 'test_helper'

class TaskFilterTest < ActiveSupport::TestCase

  should_have_many :qualifiers
  should_belong_to :user
  should_validate_presence_of :user
  should_validate_presence_of :name
  should_have_many :keywords, :dependent => :destroy

  context "TaskFilter.system_filter" do
    setup do
      @user = User.make
    end

    should "create and save a filter in system filter if none exists" do
      assert_nil TaskFilter.find(:first, :conditions => { :user_id => @user.id, :system => true })

      filter = TaskFilter.system_filter(@user)
      found = TaskFilter.find(:first, :conditions => { :user_id => @user.id, :system => true })
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
    
    filter.keywords_attributes = [ "keyword1", "keyword2" ]
    assert_equal "keyword1", filter.keywords[0].word
    assert_equal "keyword2", filter.keywords[1].word
  end

  # Checks task filter includes the given class in conditions
  def self.should_filter_on(klass, column_name = nil)
    should "setup filter ids for #{ klass.name }" do
      column_name ||= "#{ klass.name.downcase }_id"
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
  should_filter_on Customer
  should_filter_on User, "task_owners.user_id"
  should_filter_on Tag, "task_tags.tag_id"

  context "a normal company" do
    setup do
      @company = Company.last
      @company.create_default_properties
      Status.create_default_statuses(@company)
    end

    should "filter on custom attributes separately" do
      type = @company.type_property
      priority = @company.priority_property
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
      expected = "(lower(tasks.name) like '%keyword1%' or lower(tasks.description) like '%keyword1%'"
      expected += " or lower(tasks.name) like '%keyword2%' or lower(tasks.description) like '%keyword2%')"

      assert_not_nil conditions.index(expected)
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

      @filter = TaskFilter.new(:user => @user)
      @filter.qualifiers.build(:qualifiable => @project)
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

  end
end
