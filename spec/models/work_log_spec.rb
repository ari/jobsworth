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

  describe "all_accessed_by(user) scope" do
    before(:each) do
      company=Company.make
      @user=User.make(:company=>company)
      3.times{ WorkLog.make(:company=>company, :customer=>Customer.make) }
      project= company.projects.first
      project.completed_at=Time.now.utc
      project.save!
      @user.projects<< company.projects
      3.times{ WorkLog.make }
    end
    it "should scope work logs by user's company" do
      WorkLog.all_accessed_by(@user).each{ |work_log| work_log.company_id.should == @user.company_id}
    end
    it "should scope work logs by all user's projects, even compalted" do
      WorkLog.all_accessed_by(@user).each{|work_log| @user.all_project_ids.should include(work_log.project_id) }
    end
    it "should return work logs with access level lower or equal to  user's access level" do
      WorkLog.all_accessed_by(@user).should have(3).work_logs
    end
    it "should return work logs for only watched tasks if user not have can see unwatched permission" do
      permission=@user.project_permissions.first
      permission.remove('see_unwatched')
      permission.save!
      WorkLog.all_accessed_by(@user).should have(2).work_logs
      WorkLog.all_accessed_by(@user).each{ |work_log| work_log.task.project_id.should_not == permission.project_id}
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
    it "should return work logs for only watched tasks if user not have can see unwatched permission" do
      permission=@user.project_permissions.first
      permission.remove('see_unwatched')
      permission.save!
      WorkLog.all_accessed_by(@user).should have(2).work_logs
      WorkLog.all_accessed_by(@user).each{ |work_log| work_log.task.project_id.should_not == permission.project_id}
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

  describe "notify()" do
    before(:each) do
      company=Company.make
      2.times{ User.make(:access_level_id=>1, :company=> company) }
      2.times{ User.make(:access_level_id=>2, :company=> company) }
      company.reload
      @task= Task.make(:company=>company, :users=>company.users)
      @work_log=WorkLog.make(:user=> User.first, :task=>@task, :body=>"some text", :company=>company, :user=>company.users.first)
    end

    it "should send emails to task's notify emails, only if work log's access level is public" do
      ActionMailer::Base.deliveries=[]
      @task.notify_emails = email= "some.email@domain.com"
      @work_log.access_level_id=2
      @work_log.notify()
      ActionMailer::Base.deliveries.map{ |email| email.to }.flatten.should_not include(email)
    end

    it "should send emails to users with access level great or equal to work log's access level" do
      ActionMailer::Base.deliveries=[]
      @work_log.notify()
      ActionMailer::Base.deliveries.map{ |email| email.to }.flatten.should == @task.users.collect{ |user| user.email }
      @work_log.access_level_id=2
      ActionMailer::Base.deliveries=[]
      @work_log.notify()
      ActionMailer::Base.deliveries.map{ |email| email.to }.flatten.should == @task.users.find_all_by_access_level_id(2).collect{ |user| user.email }
    end
  end
  describe "#for_task(task)" do
    before(:each) do
      @task= Task.make
      @work_log= WorkLog.new
      @work_log.for_task(@task)
    end
    it "should set self.task to task" do
      @work_log.task.should == @task
    end
    it "should set self.project to task.project" do
      @work_log.project.should == @task.project
    end
    it "should set self.company to task.project.company" do
      @work_log.company.should == @task.project.company
    end
    it "should set self.customer to task.project.customer" do
      @work_log.customer.should == @task.project.customer
    end
  end
end



# == Schema Information
#
# Table name: work_logs
#
#  id               :integer(4)      not null, primary key
#  user_id          :integer(4)      default(0)
#  task_id          :integer(4)
#  project_id       :integer(4)      default(0), not null
#  company_id       :integer(4)      default(0), not null
#  customer_id      :integer(4)      default(0), not null
#  started_at       :datetime        not null
#  duration         :integer(4)      default(0), not null
#  body             :text
#  paused_duration  :integer(4)      default(0)
#  exported         :datetime
#  status           :integer(4)      default(0)
#  access_level_id  :integer(4)      default(1)
#  email_address_id :integer(4)
#
# Indexes
#
#  work_logs_company_id_index                 (company_id)
#  work_logs_customer_id_index                (customer_id)
#  work_logs_project_id_index                 (project_id)
#  work_logs_task_id_index                    (task_id,log_type)
#  index_work_logs_on_task_id_and_started_at  (task_id,started_at)
#  work_logs_user_id_index                    (user_id,task_id)
#

