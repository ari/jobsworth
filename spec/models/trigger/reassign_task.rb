require 'spec_helper'
describe Trigger::ReassignTask do
  before(:each) do
    @action = Trigger::ReassignTask.new
    company = Company.first || Company.make
    company.users.destroy_all
    @task = Task.make(:company=>company)
    2.times { @task.watchers<< User.make(:company=>company, :projects=>[@task.project]) }
    2.times { @task.owners<< User.make(:company=>company, :projects=>[@task.project])   }
    @user= User.make(:company=>company, :projects=>[@task.project])
    @action.user=@user
  end
  it "should assign task to user" do
    @task.users.should_not include(@user)
    @action.execute(@task)
    @task.owners.should == [@user]
  end
  it "should move current task owners to watchers" do
    owner=@task.owners.first
    @task.watchers.should_not include(owner)
    @action.execute(@task)
    @task.watchers.should include(owner)
  end

  it "should save the task" do
    @action.execute(@task)
    @task.owners.should == [@user]
    @task.reload
    @task.owners.should == [@user]
  end
end
