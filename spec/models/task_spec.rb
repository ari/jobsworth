require 'spec_helper'

describe Task do
  before(:each) do
    @valid_attributes = {

    }
  end

  it "should create a new instance given valid attributes" do
    pending
    Task.create!(@valid_attributes)
  end
  context "task users" do
    it "should create new owner using Task#owners association" do
      pending
        @task.owners.create @user
    end
    it "should create new watcher using Task#watchers association"
    context "when add owner using Task#owners" do
      it "should include owner in users"
      it "should include owner's task_user join model in linked_user_notifications"
      it "should include owner's name in owners"
    end
  end
  context "accessed_by(user)" do
    before(:each) do
      company= Company.make
      3.times{ Project.make(:company=>company)}
      @user = User.make(:company=> company)
      [0,1].each do |i|
        @user.projects<< company.projects[i]
        2.times { company.projects[i].tasks.make(:company=>company, :users=>[@user]) }
        company.projects[i].tasks.make(:company=>company)
      end
      company.projects.last.tasks.make
      Project.make.tasks.make
    end
    it "should return tasks only from user's company" do
      Task.accessed_by(@user).each do |task|
        @user.company.tasks.should include(task)
      end
    end
    it "should return tasks only from user's not completed projects" do
      project= @user.projects.first
      project.completed_at= Time.now.utc
      project.save!
      Task.accessed_by(@user).should == Task.all(:conditions=> ["tasks.project_id in(?)", @user.project_ids])
    end
    it "should return only watched tasks if user not have can_see_unwatched permission" do
      permission=@user.project_permissions.first
      permission.remove('see_unwatched')
      permission.save!
      @user.reload
      Task.accessed_by(@user).each do |task|
        @user.should be_can(task.project, 'see_unwatched') unless task.users.include?(@user)
      end
    end
  end

end
