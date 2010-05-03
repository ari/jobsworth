require 'spec_helper'
def set_up_event_logs
  company=Company.make
  customer = Customer.make(:company=>company)
  user=User.make(:company=>company)
  #create worklogs
  3.times { WorkLog.make(:company=>company, :customer=>customer) }
  2.times { WorkLog.make(:company=>company, :customer=>customer, :project=>company.projects.first, :access_level_id=>2)}
  user.projects<< company.projects
  3.times { WorkLog.make }
  #project files
  3.times { ProjectFile.make}
  user.projects.each { |project| ProjectFile.make(:project=>project,:company=>company)}
  #create posts
  forum=Forum.make(:company=>company, :project=>user.projects.first)
  3.times { post=Post.make(:user=>user, :forum=>forum); post.forum=forum; post.save! }
  3.times { Post.make}
  # don't test wiki, because event logs created in WikiController
  #3.times { WikiPage.make(:company=>company)}
  #3.times { WikiPage.make}
  return user
end
describe EventLog do
  describe "accessed_by(user) named scope" do
    before(:each) do
      @user=set_up_event_logs
      @logs=EventLog.accessed_by(@user)
      EventLog.count.should == 20
    end

    it "should return event logs for  work logs accessed by user" do
      permission = @user.project_permissions.first
      permission.remove('see_unwatched')
      permission.save!
      @logs.collect{ |log| log.target.is_a?(WorkLog) ? log.target : nil}.compact.sort.should == WorkLog.accessed_by(@user)
    end

    it "should return event logs for project files from user's projects" do
      @logs.collect{ |log| log.target.is_a?(ProjectFile) ? log.target : nil}.compact.each do |project_file|
        @user.projects.should include(project_file.project)
        project_file.company.should == @user.company
      end
    end

    it "should return event logs for wiki pages from user's company " do
      pending("first move event log creation from WikiController to WikiPage model")
      @logs.collect{ |log| log.target.is_a?(WikiPage) ? log.target : nil}.compact.each do |wiki_page|
        wiki_page.company.should == @user.company
      end
    end

    it "should return event logs for posts from  user.company forum" do
      @logs.collect{ |log| log.target.is_a?(Post) ? log.target : nil}.compact.each do |post|
        post.company_id.should == @user.company_id
        @user.project_ids.should include(post.project_id)
      end
    end
  end
  describe "event_logs_for_timeline(current_user, params)" do
    before(:each) do
      @user= set_up_event_logs
      @params= { :filter_project=>0, :filter_user=>0, :filter_status=>0, :filter_date=>-1}
    end
    it "should return event logs only for current_user.projects or project NULL or project = 0" do
      project=@user.company.projects.make
      WorkLog.make(:project=>project)
      logs, work_logs= EventLog.event_logs_for_timeline(@user, @params.merge(:filter_project=>project.id))
      logs.should be_empty
      work_logs.should be_empty
    end
    it "should return event logs for given params[:filter_user] user id" do

    end
    it "should return event logs for given params[:filter_project] project id " do

    end
    describe "when params[:filter_status] in FORUM_NEW_POST, WIKI_CREATED, WIKI_MODIFIED, RESOURCE_PASSWORD_REQUESTED" do
      before(:each) do
        @params.merge!(:filter_status=>EventLog::FORUM_NEW_POST)
      end
      it "should return event logs as first return value" do
        EventLog.event_logs_for_timeline(@user, @params).first.first.should be_kind_of(EventLog)
      end
      it "should return work logs for event logs as second return value" do
        EventLog.event_logs_for_timeline(@user, @params)[1].should be_nil
      end
    end
    describe "when params[:filter_status] in TASK_WORK_ADDED, TASK_MODIFIED, TASK_COMMENT, TASK_COMPLETED, TASK_REVERTED, TASK_CREATED" do
      it "should return only work logs" do
        result= EventLog.event_logs_for_timeline(@user, @params)
        result[0][0].should be_kind_of(WorkLog)
        result[1].should be_nil
      end
    end
  end
end
