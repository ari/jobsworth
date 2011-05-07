require "test_helper"

class TriggerTest < ActiveSupport::TestCase
  should belong_to(:company)
  should belong_to(:task_filter)
  should validate_presence_of(:company)

  context "a normal 'on create' trigger" do
    setup do
      company = Company.make
      customer = Customer.make(:company => company)
      user = User.make(:company => company)
      project = Project.make(:customer => customer,
                             :company => company,
                             :users => [ user ])

      @filter = TaskFilter.make(:company => company, :user => user)
      @trigger = company.triggers.make(:event_id => 1,
                                       :task_filter => @filter,
                                       :action => "task.update_attributes(:name => 'name from trigger')")
      @task = company.tasks.make_unsaved(:project => project, :creator => user)
      @task.save!
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
#  created_at     :datetime
#  updated_at     :datetime
#  event_id       :integer(4)
#

