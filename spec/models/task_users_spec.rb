require 'spec_helper'

describe TaskUsers do
  before(:each) do
    @valid_attributes = {
      :user_id => 1,
      :task_id => 1,
      :owner => false,
      :unread => false,
      :notified_last_change => false
    }
  end

  it "should create a new instance given valid attributes" do
    TaskUsers.create!(@valid_attributes)
  end
end
