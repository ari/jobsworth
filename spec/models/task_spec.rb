require 'spec_helper'

describe Task do
  before(:each) do
    @valid_attributes = {

    }
  end

  it "should create a new instance given valid attributes" do
    pending
    Task.create!(@valid_attributes)
  end
  context "task users" do
    it "should create new owner using Task#owners association" do
      pending
        @task.owners.create @user
    end
    it "should create new watcher using Task#watchers association"
    context "when add owner using Task#owners" do
      it "should include owner in users"
      it "should include owner's task_user join model in linked_user_notifications"
      it "should include owner's name in owners"
    end
  end

end
