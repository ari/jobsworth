require 'spec_helper'

describe WorkLog do
  it { should belong_to :access_level }

  it "should have access level with id 1 by default" do
    expect(subject.access_level_id).to eql 1
  end

  describe ".build_work_added_or_comment(task, user, params)" do
    let(:task) { TaskRecord.make }
    let(:user) { User.make }

    subject {
      WorkLog.build_work_added_or_comment( task, user,
        { work_log: { body: "abcd", access_level_id: 2 },
          comment: 'comment'}) }

    it "should change access_level if presented in params[:work_log] " do
      expect(subject.access_level_id).to eql 2
    end
  end

  describe ".level_accessed_by(user) scope" do
    before do
      FactoryGirl.create_list :work_log, 3
      FactoryGirl.create_list :work_log, 3, access_level_id: 2
    end

    let(:user_level_1) { FactoryGirl.create :user, access_level_id: 1 }
    let(:user_level_2) { FactoryGirl.create :user, access_level_id: 2 }

    it "should return work logs with access level lower or equal to  user's access level" do
      expect(described_class.count).to eql 6

      expect( described_class.level_accessed_by(user_level_1).count ).to eql(3)
      expect( described_class.level_accessed_by(user_level_2).count ).to eql(6)
    end
  end

  describe ".all_accessed_by(user) scope" do
    let(:company) { FactoryGirl.create :company }
    let(:company2) { FactoryGirl.create :company }
    let(:user)    { FactoryGirl.create(:user, company: company) }

    let!(:projects) { FactoryGirl.create_list :project, 3, company: company }
    let(:project1)  { projects.first }
    let(:project2)  { projects.second }
    let(:project3)  { projects.third }

    let(:customer1) { FactoryGirl.create :customer }
    let(:customer2) { FactoryGirl.create :customer, company: company }

    let!(:work_logs_1) { FactoryGirl.create_list :work_log, 3, company: company, customer: customer1, project: project1 }
    let!(:work_logs_2) { FactoryGirl.create_list :work_log, 2, company: company, customer: customer2, project: project3 }
    let!(:work_logs_3) { FactoryGirl.create_list :work_log, 3, company: company2 }

    subject { described_class.all_accessed_by(user) }

    before(:each) do
      project1.update_attribute :completed_at, Time.now.utc
      user.projects << company.projects
    end

    it "should scope work logs by user's company" do
      subject.map(&:company_id).uniq.should == [company.id]
    end

    it "should scope work logs by all user's projects, even compalted" do
      subject.each{|work_log| user.all_project_ids.should include(work_log.project_id) }
    end

    it "should return work logs with access level lower or equal to  user's access level" do
      expect(subject).to match_array work_logs_1 + work_logs_2
    end

    it 'should return work logs from projects where the user have "can_see_unwatched" permission' do
      permission = user.project_permissions.where(project_id: project1.id).first
      permission.update_attribute :can_see_unwatched, false

      subject.should have(2).work_logs
      subject.each { |work_log| work_log.task.project_id.should_not == permission.project_id }
    end
  end

  describe ".accessed_by(user) scope" do
    let(:company) { FactoryGirl.create :company }
    let(:company2) { FactoryGirl.create :company }
    let(:user)    { FactoryGirl.create(:user, company: company) }

    let!(:projects) { FactoryGirl.create_list :project, 3, company: company }
    let(:project1)  { projects.first }
    let(:project2)  { projects.second }
    let(:project3)  { projects.third }

    let(:customer1) { FactoryGirl.create :customer }
    let(:customer2) { FactoryGirl.create :customer, company: company }

    let!(:work_logs_1) { FactoryGirl.create_list :work_log, 3, company: company, customer: customer1, project: project1 }
    let!(:work_logs_2) { FactoryGirl.create_list :work_log, 2, company: company, customer: customer2, project: project3 }
    let!(:work_logs_3) { FactoryGirl.create_list :work_log, 3, company: company2 }

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
    let(:company)               { FactoryGirl.create :company }
    let!(:users_with_acc_lvl_1) { FactoryGirl.create_list(:user, 2, access_level_id: 1, company: company) }
    let!(:users_with_acc_lvl_2) { FactoryGirl.create_list(:user, 2, access_level_id: 2, company: company) }
    let!(:task)                  { FactoryGirl.create :task, company: company, users: company.reload.users }
    let(:access_level_id)       { 1 }
    let!(:work_log) { FactoryGirl.create(:work_log,
                                        task: task,
                                        access_level_id: access_level_id,
                                        company: company,
                                        user: users_with_acc_lvl_1.first) }

    before(:each) { ActionMailer::Base.deliveries = [] }

    subject { ActionMailer::Base.deliveries.map(&:to).flatten }

    it "should send emails to users with access level greater or equal to work log's access level" do
      work_log.notify
      expect(subject).to match_array task.users.collect(&:email)
    end

    context "when the work log's access_level is public(id:2)" do
      let(:access_level_id) { 2 }
      let(:email) { 'some.email@domain.com' }

      it "should send emails to task's notify emails only" do
        task.unknown_emails = email
        work_log.notify

        expect(subject).to_not be_empty
        expect(subject).to_not include(email)
        expect(subject).to match_array task.users.find_all_by_access_level_id(2).collect(&:email)
      end
    end
  end

  describe "#for_task(task)" do
    before(:each) do
      @task= FactoryGirl.create :task
      @work_log= FactoryGirl.create :work_log
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

  describe '.duration_per_user' do
    let(:user1) { FactoryGirl.create :user }
    let(:user2) { FactoryGirl.create :user }
    let(:now)   { Time.now }

    let!(:log1) { described_class.create!({started_at: now, user: user1, duration: 500}) }
    let!(:log2) { described_class.create!({started_at: now, user: user1, duration: 500}) }
    let!(:log3) { described_class.create!({started_at: now, user: user2, duration: 500}) }

    it 'should aggregate durations by user' do
      expect(described_class.duration_per_user.to_a.size).to eql 2
      expect(described_class.duration_per_user.map(&:duration)).to match_array [1000, 500]
      expect(described_class.duration_per_user.map(&:user_id)).to match_array [user1.id, user2.id]
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

