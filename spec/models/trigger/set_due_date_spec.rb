require 'spec_helper'
describe Trigger::SetDueDate do
  before(:all) do
    @action = Trigger::SetDueDate.new
    @task= Task.make
  end
  it "should set task's due date in days(e.g. 3) from today" do
    @action.days=4
    @action.execute(@task)
    @task.due_at.to_date.should == (Time.now.utc + 4.days).to_date
  end
  it "should set due date event if task already has due date" do
    @task.due_at = Time.now.utc + 12.days
    @task.save!
    @action.days=5
    @action.execute(@task)
    @task.due_at.to_date.should == (Time.now.utc + 5.days).to_date
  end
  it "should save task" do
    @action.days=5
    @action.execute(@task)
    @task.due_at.to_date.should == (Time.now.utc + 5.days).to_date
    @task.reload
    @task.due_at.to_date.should == (Time.now.utc + 5.days).to_date
  end
end

# == Schema Information
#
# Table name: trigger_actions
#
#  id         :integer(4)      not null, primary key
#  trigger_id :integer(4)
#  name       :string(255)
#  type       :string(255)
#  argument   :integer(4)
#  created_at :datetime
#  updated_at :datetime
#

