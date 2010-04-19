require 'spec_helper'

describe WorkLog do
  it "should belongs to  AccessLevel" do
    WorkLog.reflect_on_association(:access_level).should_not be_nil
  end

  it "should have access level with id 1 by default" do
    work_log=WorkLog.new
    work_log.access_level_id.should == 1
  end
  describe "WorkLog.build_work_added_or_comment(task, user, params)" do
    it "should change access_level if presented in params[:work_log] " do
      work_log=WorkLog.build_work_added_or_comment(Task.make, User.make, { :work_log=>{ :body=>"abcd", :access_level_id=>2}, :comment=>'comment'})
      work_log.access_level_id.should == 2
    end
  end
  describe "level_accessed_by(user) scope" do
    it "should return work logs with access level lower or equal to  user's access level" do
      3.times{ WorkLog.make }
      3.times{ WorkLog.make(:access_level_id=>2) }
      WorkLog.all.should have(6).work_logs
      WorkLog.level_accessed_by(User.make(:access_level_id=>1)).should have(3).work_logs
      WorkLog.level_accessed_by(User.make(:access_level_id=>2)).should have(6).work_logs
    end
  end
  describe "accessed_by(user) scope" do
    before(:each) do
      company=Company.make
      @user=User.make(:company=>company)
      3.times{ WorkLog.make(:company=>company, :customer=>Customer.make) }
      @user.projects<< company.projects
      3.times{ WorkLog.make }
    end
    it "should scope work logs by user's company" do
      WorkLog.accessed_by(@user).each{ |work_log| work_log.company_id.should == @user.company_id}
    end
    it "should scope work logs by user's projects" do
      WorkLog.accessed_by(@user).each{|work_log| @user.project_ids.should include(work_log.project_id) }
    end
    it "should return work logs with access level lower or equal to  user's access level" do
      WorkLog.accessed_by(@user).should have(3).work_logs
    end
  end
  describe "on_tasks_owned_by(user) scope" do
    before(:each) do
      @user=User.make
      3.times{ WorkLog.make(:task=>Task.make(:users=>[@user]))}
      2.times{ WorkLog.make}
    end
    it "should scope work logs by user's tasks" do
      WorkLog.all.count.should == 5
      WorkLog.on_tasks_owned_by(@user).should have(3).work_logs
      WorkLog.on_tasks_owned_by(@user).each{ |work_log| work_log.task.user_ids.should include(@user.id)}
    end
  end
end
