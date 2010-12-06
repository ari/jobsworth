require 'spec_helper'
def it_should_has_predefined_action(action)
  it "should has predefined action '#{action}'" do
    Trigger::Action.all.detect{ |a| a.name == action}.should_not be_nil
  end
end
describe Trigger::Action do
  before(:all) do
    @action = Trigger::Action.new
  end

  it "should has id attribute" do
    @action.id = 12
    @action.id.should == 12
  end

  it "should has name attribute" do
    @action.name = "reassing"
    @action.name.should == "reassing"
  end

  it_should_has_predefined_action("Reassign task to user")
  it_should_has_predefined_action("Send email")
  it_should_has_predefined_action("Set due date")

  describe "set due date action" do
    before(:all) do
      @action = Trigger::Action.find_by_name("Set due date")
      @task= Task.make
    end
    it "should set task's due date in days(e.g. 3) from today" do
      @action.execute(:task=>@task, :days=> 4)
      @task.due_at.to_date.should == (Time.now + 4.days).to_date
    end
    it "should set due date event if task already has due date" do
      @task.due_at = Time.now + 12.days
      @task.save!
      @action.execute(:task=>@task, :days=>5)
      @task.due_at.to_date.should == (Time.now + 5.days).to_date
    end
  end

  it "should can return action by id" do
    Trigger::Action.find(1).should be_kind_of(Trigger::Action)
  end

  it "should can return action by name" do
    Trigger::Action.find_by_name("Set due date").name.should == "Set due date"
  end
end
