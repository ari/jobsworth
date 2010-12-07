require 'spec_helper'
def it_should_has_predefined_action_factory(action)
  it "should has predefined action factory '#{action}'" do
    Trigger::ActionFactory.all.detect{ |a| a.name == action}.should_not be_nil
  end
end

describe Trigger::ActionFactory do
  before(:all) do
    @action_factory = Trigger::ActionFactory.new
  end

  it "should has id attribute" do
    @action_factory.id = 12
    @action_factory.id.should == 12
  end

  it "should has name attribute" do
    @action_factory.name = "reassing"
    @action_factory.name.should == "reassing"
  end

  it_should_has_predefined_action_factory("Reassign task to user")
  it_should_has_predefined_action_factory("Send email")
  it_should_has_predefined_action_factory("Set due date")

  it "should can return action by id" do
    Trigger::ActionFactory.find(1).should be_kind_of(Trigger::ActionFactory)
  end

  it "should can return action by name" do
    Trigger::ActionFactory.find_by_name("Set due date").name.should == "Set due date"
  end
end
