require 'spec_helper'

def it_should_can_create_trigger_with_event(event)
  it "should can create trigger with event '#{event}'" do
    select event, :from=>'Event'
    click_button "Create"
    current_url.should =~ /triggers$/
  end
end

def it_should_can_create_trigger_with_action(action)
  it  "should can create trigger with action '#{action}'" do
    pending "UI was changed, it uses javascript so we should run this spec using celerity or selenium."
    count = Trigger.count
    select 'Task created', :from=>'Event'
    select action, :from => 'Add action'
    click_button "Create"
    current_url.should =~ /triggers$/
    Trigger.count.should == count +1
    Trigger.last.actions.last.name.should == action
  end
end
describe "User with triggers permission" do
  before(:all) do
    @user = User.make
#    @user = login_using_browser
    @user.use_triggers=true
    @user.save
  end

  describe "when creating trigger" do
    before(:each) do
#      visit '/triggers/new'
    end
#    it_should_can_create_trigger_with_event("Task created")
#    it_should_can_create_trigger_with_event("Task updated")

    it "should can create trigger with condition 'name changed'"
    it "should can create trigger with condition 'description changed'"
    it "should can create trigger with condition 'comment added'"
    it "should can create trigger with condition 'public comment added'"
    it "should can create trigger with condition 'private comment added'"
    Trigger::ActionFactory.all.each{ |action|
      it_should_can_create_trigger_with_action(action.name)
    }
  end

  describe "when edit trigger" do
    before(:each) do
      @trigger= Trigger.make(:company=>@user.company)
      @trigger.actions << Trigger::SetDueDate.new(:days=>5)
      @trigger.actions << Trigger::ReassignTask.new(:user=>@user)
      @trigger.save!
#      visit "/triggers/edit/#{@trigger.id}"
    end
    it "can see all actions" do

    end
    it "can edit any action" do

    end
  end
end

describe "User without triggers permission" do
  it "can't create trigger"
  it "can't list triggers"
  it "can't delete trigger"
  it "can't edit trigger"
end
describe "List existing triggers," do
  describe "a user with triggers permission" do
    it "should see only own triggers"
    it "can delete any own trigger"
    it "can edit any own trigger"
  end
  describe "an admin" do
    it "should see all triggers in company"
    it "can delete any trigger in company"
    it "can edit any trigger in company"
  end
end
