require 'spec_helper'
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
end
