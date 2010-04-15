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
  describe "project_ids_for_sql" do
    before(:each) do
      @user=User.make
    end
    it "should return project ids joined by ',' if user have prjects" do
      3.times{ @user.projects<< Project.make }
      @user.project_ids_for_sql.should == @user.project_ids.join(',')
    end
    it "should return '0' if user not have any project" do
      @user.projects.clear
      @user.project_ids_for_sql.should == "0"
    end
  end
end
