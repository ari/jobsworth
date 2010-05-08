require 'spec_helper'

describe ScmChangeset do
  before(:each) do
    @scm_project=ScmProject.make
    @valid_attributes = {
      :author => 'user',
      :commit_date=> Time.now,
      :message => "Initial import",
      :scm_project=> @scm_project
    }
    @user = User.make(:company=>@scm_project.company, :projects=>[@scm_project.project])
  end

  it "should create a new instance given valid attributes" do
    ScmChangeset.create!(@valid_attributes)
  end
  it "should try to map author -> user email" do
    @valid_attributes[:author]= @user.email
    ScmChangeset.create!(@valid_attributes).user.should == @user
  end
  it "should try to map author -> user name" do
    @valid_attributes[:author]= @user.username
    ScmChangeset.create!(@valid_attributes).user.should == @user
  end
  it "should try to map author -> user full name" do
    @valid_attributes[:author]= @user.name
    ScmChangeset.create!(@valid_attributes).user.should == @user
  end
  context "message have task num in #(\d) format and tasks with this num exist in this project" do
    before(:each) do
      @task= Task.make(:company=>@scm_project.company, :project => @scm_project.project)
      @valid_attributes[:message]= "Commit for task ##{@task.task_num}"
      @changeset= ScmChangeset.create!(@valid_attributes)
    end
    it "should create work log for this task" do
      @changeset.work_log.should_not be_nil
      @changeset.work_log.task.should == @task
    end
    it "with project of scm_project project" do
      @changeset.work_log.project.should == @scm_project.project
    end
    it "body should include changeset message" do
      @changeset.work_log.body.should include(@valid_attributes[:message])
    end
  end
end
