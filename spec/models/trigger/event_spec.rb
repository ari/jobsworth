require 'spec_helper'

describe Trigger::Event do
  before(:each) do
    @event = Trigger::Event.new
  end

  it "should has id attribute" do
    @event.id = 12
    @event.id.should == 12
  end

  it "should has name attribute" do
    @event.name = "Task created"
    @event.name.should == "Task created"
  end

  it "should has two predefined events: 'Task created' and 'Task updated'" do
    Trigger::Event.all.map{ |e| e.name}.should == ['Task created', 'Task updated']
  end

  it "should can return event by id" do
    Trigger::Event.find(1).name.should == 'Task created'
  end
end
