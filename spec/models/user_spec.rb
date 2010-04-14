require 'spec_helper'

describe User do
  fixtures :users, :projects, :project_permissions
  before(:each) do
    @user=users(:admin)
  end
  describe "method can?" do
    it "should accept 'see_unwatched' " do
      @user.can?(@user.projects.first, 'see_unwatched').should be_true
    end
  end
  describe "access level" do
    it "should belongs to  access level" do
      User.reflect_on_association(:access_level).should_not be_nil
    end
    it "should have access level with id 1 by default" do
      user=User.new
      user.access_level_id.should == 1
    end
  end
end
