require 'spec_helper'

describe TaskFilter do
  before(:each) do
    @valid_attributes = {

    }
  end

  describe ".recent_for(user) scope" do
    it "should return recent task filters for user" do
      user=User.make
      filters=[]
      4.times{ filters<< TaskFilter.make(:user=>user, :recent_for_user_id=>user.id, :company=>user.company)}
      4.times{ TaskFilter.make(:user=>user, :company=>user.company)}
      TaskFilter.recent_for(user).should == filters
    end
  end
end
