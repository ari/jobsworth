require 'spec_helper'
def it_should_can_create_trigger_with_event(event)
  it "should can create trigger with event '#{event}'" do
    select event, :from=>'Event'
    click_button "Save"
    page.should have_content("Trigger created")
  end
end
describe "User with triggers permission, when creating triggers" do
  before(:each) do
    @user= login_using_browser
    @user.use_triggers=true
    @user.save
    visit 'triggers/new'
  end
  it_should_can_create_trigger_with_event("Task created")
  it_should_can_create_trigger_with_event("Task updated")
  it "should can create trigger with condition 'name changed'"
  it "should can create trigger with condition 'description changed'"
  it "should can create trigger with condition 'comment added'"
  it "should can create trigger with condition 'public comment added'"
  it "should can create trigger with condition 'private comment added'"
  it "should can create trigger with action 'send email to task users'"
  it "should can create trigger with action 'set due date(relative to current date)'"
  it "should can create trigger with action 'reassign task'"
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
