require 'test_helper'

class TriggerTest < ActiveSupport::TestCase
  should_belong_to :company
  should_belong_to :task_filter
  should_validate_presence_of :fire_on
  should_validate_presence_of :company

  context "a normal 'on create' trigger" do
    setup do
      company = Company.make
      customer = Customer.make(:company => company)
      user = User.make(:company => company)
      project = Project.make(:customer => customer,
                             :company => company,
                             :users => [ user ])
      
      @filter = TaskFilter.make(:company => company, :user => user)
      @trigger = company.triggers.make(:fire_on => "create",
                                       :task_filter => @filter,
                                       :action => "task.update_attributes(:name => 'name from trigger')")
      @task = company.tasks.make_unsaved(:project => project)
      @task.save!
    end
    
    should "set the name in action" do
      assert_equal "name from trigger", @task.reload.name
    end 

    should "not set the name on normal, non-create save" do
      @task.name = "other name"
      @task.save!
      assert_equal "other name", @task.reload.name
    end

  end
end
