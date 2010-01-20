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
      @task = company.tasks.make_unsaved(:project => project, :creator => user)
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

  context "a unsaved trigger" do
    setup do
      @trigger = Trigger.make
    end

    should "setup action from params for when trigger_type == 'due_at'" do
      @trigger.trigger_type = "due_at"
      @trigger.count = 3
      @trigger.period = "weeks"
      assert @trigger.action.blank? 

      @trigger.save!
      assert_equal "task.update_attributes(:due_at => Time.now + 3.weeks)", @trigger.action
    end
  end
end

# == Schema Information
#
# Table name: triggers
#
#  id             :integer(4)      not null, primary key
#  company_id     :integer(4)
#  task_filter_id :integer(4)
#  fire_on        :text
#  action         :string(255)
#  created_at     :datetime
#  updated_at     :datetime
#

