require 'spec_helper'
def it_should_has_predefined_action_factory(action)
  it "should has predefined action factory '#{action}'" do
    expect(Trigger::ActionFactory.all.detect{ |a| a.name == action}).not_to be_nil
  end
end

describe Trigger::ActionFactory do
  before(:all) do
    @action_factory = Trigger::ActionFactory.new
  end

  it "should has id attribute" do
    @action_factory.id = 12
    expect(@action_factory.id).to eq(12)
  end

  it "should has name attribute" do
    @action_factory.name = "reassing"
    expect(@action_factory.name).to eq("reassing")
  end

  it_should_has_predefined_action_factory("Reassign task to user")
  it_should_has_predefined_action_factory("Send email")
  it_should_has_predefined_action_factory("Set due date")

  it "should can return action by id" do
    expect(Trigger::ActionFactory.find(1)).to be_kind_of(Trigger::ActionFactory)
  end

  it "should can return action by name" do
    expect(Trigger::ActionFactory.find_by_name("Set due date").name).to eq("Set due date")
  end
end
