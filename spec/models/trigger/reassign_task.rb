require 'spec_helper'
describe Trigger::ReassignTask do
  before(:each) do
    @action = Trigger::ReassignTask.new
    company = Company.first || Company.make
    company.users.destroy_all
    @task = TaskRecord.make(:company=>company)
    2.times { @task.watchers<< User.make(:company=>company, :projects=>[@task.project]) }
    2.times { @task.owners<< User.make(:company=>company, :projects=>[@task.project])   }
    @user= User.make(:company=>company, :projects=>[@task.project])
    @action.user=@user
  end
  it 'should assign task to user' do
    expect(@task.users).not_to include(@user)
    @action.execute(@task)
    expect(@task.owners).to eq([@user])
  end
  it 'should move current task owners to watchers' do
    owner=@task.owners.first
    expect(@task.watchers).not_to include(owner)
    @action.execute(@task)
    expect(@task.watchers).to include(owner)
  end

  it 'should save the task' do
    @action.execute(@task)
    expect(@task.owners).to eq([@user])
    @task.reload
    expect(@task.owners).to eq([@user])
  end
end
