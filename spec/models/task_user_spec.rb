require 'spec_helper'

describe TaskUser do
  before(:each) do
    @valid_attributes = {
      :user_id => 1,
      :task_id => 1,
      :unread => false,
    }
  end

  it "should create a new instance given valid attributes" do
    TaskUser.create!(@valid_attributes)
  end
end
