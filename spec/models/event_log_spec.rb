require 'spec_helper'

describe EventLog do
  describe "accessed_by(user) named scope" do
    before(:each) do
      company=Company.make
      customer = Customer.make(:company=>company)
      @user=User.make(:company=>company)
      #create worklogs
      3.times { WorkLog.make(:company=>company, :customer=>customer) }
      2.times { WorkLog.make(:company=>company, :customer=>customer, :project=>company.projects.first, :access_level_id=>2)}
      @user.projects<< company.projects
      3.times { WorkLog.make }
      #project files
      3.times { ProjectFile.make}
      @user.projects.each { |project| ProjectFile.make(:project=>project,:company=>company)}
      #create posts
      forum=Forum.make(:company=>company, :project=>@user.projects.first)
      3.times { post=Post.make(:user=>@user, :forum=>forum); post.forum=forum; post.save! }
      3.times { Post.make}
      # don't test wiki, because event logs created in WikiController
      #3.times { WikiPage.make(:company=>company)}
      #3.times { WikiPage.make}
      @logs=EventLog.accessed_by(@user)
      EventLog.count.should == 20
    end

    it "should return event logs for  work logs accessed by user" do
      @logs.collect{ |log| log.target.is_a?(WorkLog) ? log.target : nil}.compact.should == WorkLog.accessed_by(@user)
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
end
