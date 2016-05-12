require 'spec_helper'

describe Trigger::Event do
  before(:each) do
    @event = Trigger::Event.new
  end

  it "should has id attribute" do
    @event.id = 12
    expect(@event.id).to eq(12)
  end

  it "should has name attribute" do
    @event.name = "Task created"
    expect(@event.name).to eq("Task created")
  end

  it "should has two predefined events: 'Task created' and 'Task updated'" do
    expect(Trigger::Event.all.map{ |e| e.name}).to eq(['Task created', 'Task updated'])
  end

  it "should can return event by id" do
    expect(Trigger::Event.find(1).name).to eq('Task created')
  end
end
