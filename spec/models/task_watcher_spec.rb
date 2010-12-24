require 'spec_helper'

describe TaskWatcher do
  before(:each) do
    @valid_attributes = {
      
    }
  end

  it "should create a new instance given valid attributes" do
    TaskWatcher.create!(@valid_attributes)
  end
end

# == Schema Information
#
# Table name: task_users
#
#  id         :integer(4)      not null, primary key
#  user_id    :integer(4)
#  task_id    :integer(4)
#  type       :string(255)     default("TaskOwner")
#  unread     :boolean(1)
#  created_at :datetime
#  updated_at :datetime
#

