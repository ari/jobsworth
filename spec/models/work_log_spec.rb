require 'spec_helper'

describe WorkLog do
  it "should belongs to  AccessLevel" do
    WorkLog.reflect_on_association(:access_level).should_not be_nil
  end

  it "should have access level with id 1 by default" do
    work_log=WorkLog.new
    work_log.access_level_id.should == 1
  end

  describe ".build_work_added_or_comment(task, user, params)" do
    it "should change access_level if presented in params[:work_log] " do
      work_log=WorkLog.build_work_added_or_comment(TaskRecord.make, User.make, { :work_log=>{ :body=>"abcd", :access_level_id=>2}, :comment=>'comment'})
      work_log.access_level_id.should == 2
    end
  end

  describe ".level_accessed_by(user) scope" do
    it "should return work logs with access level lower or equal to  user's access level" do
      3.times{ WorkLog.make }
      3.times{ WorkLog.make(:access_level_id=>2) }
      WorkLog.all.should have(6).work_logs
      WorkLog.level_accessed_by(User.make(:access_level_id=>1)).should have(3).work_logs
      WorkLog.level_accessed_by(User.make(:access_level_id=>2)).should have(6).work_logs
    end
  end

  describe ".all_accessed_by(user) scope" do
    let(:company) { Company.make }
    let(:user)    { User.make(company: company) }

    let!(:projects) { 3.times.map{ Project.make(company: company) } }
    let(:project1)  { projects.first }
    let(:project2)  { projects.second }
    let(:project3)  { projects.third }

    let!(:work_logs_1) { 3.times.map{ WorkLog.make(company: company, customer: Customer.make, project: project1) } }
    let!(:work_logs_2) { 2.times.map{ WorkLog.make(company: company, customer: Customer.make(company: company), project: project3) } }
    let!(:work_logs_3) { 3.times.map{ WorkLog.make } }

    before(:each) do
      project1.update_attribute :completed_at, Time.now.utc
      user.projects << company.projects
    end

    it "should scope work logs by user's company" do
      described_class.all_accessed_by(user).each{ |work_log| work_log.company_id.should == user.company_id}
    end

    it "should scope work logs by all user's projects, even compalted" do
      described_class.all_accessed_by(user).each{|work_log| user.all_project_ids.should include(work_log.project_id) }
    end

    it "should return work logs with access level lower or equal to  user's access level" do
      described_class.all_accessed_by(user).should have(5).work_logs
    end

    it 'should return work logs from projects where the user have "can_see_unwatched" permission' do
      permission = user.project_permissions.where(project_id: project1.id).first
      permission.update_attribute :can_see_unwatched, false

      described_class.all_accessed_by(user).should have(2).work_logs
      described_class.all_accessed_by(user).each{ |work_log| work_log.task.project_id.should_not == permission.project_id}
    end
  end

  describe ".accessed_by(user) scope" do
    let(:company) { Company.make }
    let(:user)    { User.make(company: company) }

    let!(:projects) { 3.times.map{ Project.make(company: company) } }
    let(:project1)  { projects.first }
    let(:project2)  { projects.second }
    let(:project3)  { projects.third }

    let!(:work_logs_1) { 3.times.map{ WorkLog.make(company: company, customer: Customer.make(company: company), project: project1) } }
    let!(:work_logs_2) { 2.times.map{ WorkLog.make(company: company, customer: Customer.make(company: company), project: project3) } }
    let!(:work_logs_3) { 3.times.map{ WorkLog.make } }

    before(:each) { user.projects << company.projects }

    it "should scope work logs by user's company" do
      WorkLog.accessed_by(user).each{ |work_log| work_log.company_id.should == user.company_id }
    end

    it "should scope work logs by user's projects" do
      WorkLog.accessed_by(user).each{ |work_log| user.project_ids.should include(work_log.project_id) }
    end

    it "should return work logs with access level lower or equal to  user's access level" do
      WorkLog.accessed_by(user).should have(5).work_logs
    end

    it "should return work logs for only watched tasks if user not have can see unwatched permission" do
      permission = user.project_permissions.where(project_id: project1.id).first
      permission.update_attribute :can_see_unwatched, false

      WorkLog.all_accessed_by(user).should have(2).work_logs
      WorkLog.all_accessed_by(user).each{ |work_log| work_log.task.project_id.should_not == permission.project_id}
    end
  end

  describe ".on_tasks_owned_by(user) scope" do
    before(:each) do
      @user=User.make
      3.times{ WorkLog.make(:task=>TaskRecord.make(:users=>[@user]))}
      2.times{ WorkLog.make}
    end
    it "should scope work logs by user's tasks" do
      WorkLog.all.count.should == 5
      WorkLog.on_tasks_owned_by(@user).should have(3).work_logs
      WorkLog.on_tasks_owned_by(@user).each{ |work_log| work_log.task.user_ids.should include(@user.id)}
    end
  end

  describe "#notify" do
    let(:company)              { Company.make }
    let!(:users_with_acc_lvl_1) { 2.times.map{ User.make(access_level_id: 1, company: company) } }
    let!(:users_with_acc_lvl_2) { 2.times.map{ User.make(access_level_id: 2, company: company) } }
    let(:task)                 { TaskRecord.make(company: company, users: company.reload.users) }
    let(:access_level_id)      { 1 }
    let(:work_log) { WorkLog.make(task: task,
                                  access_level_id: access_level_id,
                                  company: company,
                                  user: users_with_acc_lvl_1.first) }

    before(:each) { ActionMailer::Base.deliveries = [] }

    context "when the work log's access_level is public(id:2)" do
      let(:access_level_id) { 2 }

      it "should send emails to task's notify emails only" do
        task.unknown_emails = email = 'some.email@domain.com'
        work_log.notify

        ActionMailer::Base.deliveries.map(&:to).flatten.should_not include(email)
        ActionMailer::Base.deliveries.map(&:to).flatten.should match_array(
          task.users.find_all_by_access_level_id(2).collect(&:email))
      end
    end

    it "should send emails to users with access level greater or equal to work log's access level" do
      work_log.notify
      ActionMailer::Base.deliveries.map(&:to).flatten.should match_array(
        task.users.collect(&:email))
    end
  end

  describe "#for_task(task)" do
    before(:each) do
      @task= TaskRecord.make
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

