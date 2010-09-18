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
  describe "destroy" do
    before(:each) do
      @user=User.make
      @user.work_logs.clear
      @user.topics.clear
      @user.posts.clear
    end

    it "should destroy user" do
      @user.destroy
      User.find_by_id(@user.id).should be_nil
    end

    it "should not destroy if work logs exist" do
      @user.work_logs << WorkLog.make
      @user.save!
      @user.destroy.should == false
    end

    it "should not destroy if topics exist" do
      @user.topics << Topic.make
      @user.save!
      @user.destroy.should == false
    end

    it "should not destroy if posts exist" do
      @user.posts << Post.make
      @user.save!
      @user.destroy.should == false
    end

    it "should set tasks.creator_id to NULL" do
      t=Task.make(:creator=>@user, :company=>@user.company)
      t.creator.should == @user
      @user.destroy.should_not == false
      t.reload.creator.should be_nil
    end

    it "should not touch tasks.creator_id if user not destroyed" do
      t=Task.make(:creator=>@user, :company=>@user.company)
      t.creator.should == @user
      @user.work_logs << WorkLog.make
      @user.save!
      @user.destroy.should == false
      t.reload.creator.should == @user.reload
    end
  end
end
