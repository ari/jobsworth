require 'spec_helper'

describe TaskRecord do

  it "should create a new instance given valid attributes" do
    expect { TaskRecord.make }.to_not raise_error
    expect { FactoryGirl.create :task }.to_not raise_error
    expect { FactoryGirl.create :task_with_customers }.to_not raise_error
  end

  describe '#user_work' do
    subject { TaskRecord.new }
    let(:user1) { stub :user1 }
    let(:user2) { stub :user2 }

    let(:user_duration1) { stub _user_: user1, duration: 1000 }
    let(:user_duration2) { stub _user_: user2, duration: 500 }

    before { subject.stub_chain('work_logs.duration_per_user' => [user_duration1, user_duration2]) }

    its(:user_work) { should == {user1 => 1000, user2 => 500} }
  end

  describe "#public_comments" do
    before(:each) do
      @task       = FactoryGirl.create :task_with_customers
      @customer   = @task.customers.first

      @work_log   = FactoryGirl.create :work_log, customer: @customer
      @comment_1  = FactoryGirl.create :work_log_comment,
                                       customer:   @customer,
                                       task:       @task,
                                       started_at: 2.days.ago

      @comment_2  = FactoryGirl.create :work_log_comment,
                                       customer:   @customer,
                                       task:       @task,
                                       started_at: 1.day.ago
      @task.work_logs = [@comment_1, @comment_2, @work_log]
    end

    it "should return only comments" do
      task_comments = TaskRecord.public_comments_for(@task)
      expect(task_comments).to match_array [@comment_1, @comment_2]
    end

    it "shoud return only the comments that belong to customers of the task" do
      some_random_comment = FactoryGirl.create :work_log
      task_comments = TaskRecord.public_comments_for(@task)

      task_comments.should_not include(some_random_comment)
    end

    it "should return the comments ordered by the started_at date DESC" do
      task_comments = TaskRecord.public_comments_for(@task)
      task_comments.first.should == @comment_2
      task_comments.second.should == @comment_1
    end
  end

  describe ".open_only" do
    let!(:open_task)        { FactoryGirl.create :task, status: TaskRecord::OPEN }
    let!(:duplicated_task)  { FactoryGirl.create :task, status: TaskRecord::DUPLICATE }
    let!(:closed_task)      { FactoryGirl.create :task, status: TaskRecord::CLOSED }

    subject { described_class.open_only }

    it "should only return tasks with resolution open" do
      expect(TaskRecord.count).to eql 3
      expect(subject).to match_array [open_task]
    end
  end

  describe "associations" do
    subject { @task = FactoryGirl.create :task }

    it "should create new owner using 'owners' association" do
      new_owner = User.make
      subject.owners << new_owner
      subject.reload
      subject.owners.should include(new_owner)
    end

    it "should include all the owners in the 'users' association" do
      some_user     = FactoryGirl.create :user
      another_user  = FactoryGirl.create :user
      subject.owners << some_user
      subject.owners << another_user
      expect(subject.users).to match_array [some_user, another_user]
    end

    it "should create a new watcher through the 'watchers' association" do
      new_watcher = FactoryGirl.create :user
      subject.watchers << new_watcher
      subject.reload
      subject.watchers.should include(new_watcher)
    end

    it "should include all the watchers in the 'users' association" do
      some_user  = FactoryGirl.create :user
      subject.watchers << some_user
      subject.watchers.should include(some_user)
    end

    it "should include owner's task_user join model in linked_user_notifications"
  end

  describe "access scopes" do
    before(:each) do
      company = Company.make
      3.times { Project.make(:company=>company)}
      @user = User.make(:company=> company)
      [0,1].each do |i|
        @user.projects << company.projects[i]
        2.times { TaskRecord.make(company: company, project: company.projects[i], users: [@user]) }
        company.projects[i].tasks.make(:company=>company)
      end
      company.projects.last.tasks.make
      Project.make.tasks.make
    end

    describe "accessed_by(user)" do
      it "should return tasks only from user's company" do
        company_tasks           = @user.company.tasks
        tasks_accessed_by_user  = TaskRecord.accessed_by(@user)
        company_tasks.should include *tasks_accessed_by_user
      end

      context "when the user doesn't have can_see_unwatched permission" do
        it "should return only watched tasks" do
          permission = @user.project_permissions.first
          permission.update_attributes(:can_see_unwatched => 0)
          @user.reload
          TaskRecord.accessed_by(@user).each do |task|
            @user.should be_can(task.project, 'see_unwatched') unless task.users.include?(@user)
          end
        end
      end

      it "should the tasks from completed projects" do
        completed_project = @user.projects.first
        completed_project.update_attributes(:completed_at => 1.day.ago.utc)
        tasks_accessed_by_user = TaskRecord.accessed_by(@user)

        tasks_accessed_by_user.should include *completed_project.tasks
      end
    end

    context "all_accessed_by(user)" do
      it "should return tasks only from user's company" do
        TaskRecord.all_accessed_by(@user).each do |task|
          @user.company.tasks.should include(task)
        end
      end

      it "should return only watched tasks if user not have can_see_unwatched permission" do
        permission=@user.project_permissions.first
        permission.remove('see_unwatched')
        permission.save!
        @user.reload
        TaskRecord.all_accessed_by(@user).each do |task|
          @user.should be_can(task.project, 'see_unwatched') unless task.users.include?(@user)
        end
      end

      it "should return tasks from all users projects, even completed" do
        project= @user.projects.first
        project.completed_at= Time.now.utc
        project.save!
        TaskRecord.all_accessed_by(@user).should ==
          TaskRecord.all(:conditions=> ["tasks.project_id in(?)", @user.all_project_ids])
      end
    end
  end

  describe "task_property_values attributes assignment using Task#properties=(params) method" do
    before(:each) do
      @task = TaskRecord.make
      @attributes = @task.attributes.with_indifferent_access.except(:id, :type)
      @properties = @task.company.properties
      @task.set_property_value(@properties.first, @properties.first.property_values.first)
      @task.set_property_value(@properties[1], @properties[1].property_values.first)
      @task.save!
      @attributes[:properties]={
        @properties[0].id => @properties[0].property_values[1].id, #change value of first property
        @properties[1].id => "",   #second property is blank, so should be removed
        @properties[2].id => @properties[2].property_values[0].id # third property added
      }
      @task_property_values=@task.task_property_values
    end
    context "when attributes assigned" do
      before(:each) do
        @task.attributes= @attributes
      end

      it "should changed task_property_values with new values" do
        @task.attributes= @attributes
        @task.property_value(@properties[0]).should == @properties[0].property_values[1]
      end

      it "should not delete any task_property_values" do
        @task.property_value(@properties[1]).should_not be_nil
      end

      it "should build new task_property_values" do
        @task.property_value(@properties[2]).should == @properties[2].property_values[0]
      end
    end
    context "when task saved" do
      before(:each) do
        @task.attributes=@attributes
        @task.save!
        @task.reload
      end
      it "should changed task_property_values with new values" do
        @task.property_value(@properties[0]).should == @properties[0].property_values[1]
      end

      it "should delete task_property_values if value is blank" do
        @task.property_value(@properties[1]).should be_nil
      end
      it "should create new task_property_values" do
        @task.property_value(@properties[2]).should == @properties[2].property_values[0]
      end
    end
    context "when task not saved" do
      before(:each) do
        @attributes[:project_id]=""
        @task.attributes=@attributes
        @task.save.should == false
        @task.reload
      end

      it "should not change task_property_values in database" do
        @task.property_value(@properties[0]).should == @properties[0].property_values.first
        @task.property_value(@properties[1]).should == @properties[1].property_values.first
        @task.property_value(@properties[2]).should == nil
      end
    end
  end

  describe "add users, resources, dependencies to task using Task#set_users_resources_dependencies" do
    before(:each) do
      @company = Company.make
      @task = TaskRecord.make(:company=>@company)
      @user = User.make(:company=>@company, :projects=>[@task.project], :admin=>true)
      @resource = Resource.make(:company=>@company)
      @task.owners<< User.make(:company=>@company, :projects=>[@task.project])
      @task.watchers<< User.make(:company=>@company, :projects=>[@task.project])
      @task.resources<< Resource.make(:company=>@company)
      @task.dependencies<< TaskRecord.make(:company=>@company, :project=>@task.project)
      @params = {:dependencies=>[@task.dependencies.first.task_num.to_s],
                     :resource=>{:name=>'',:ids=>@task.resource_ids},
                     :assigned=>@task.owner_ids,
                     :users=>@task.user_ids}
      @task.save!
    end
    context "when task saved" do
      it "should saved new user in database if add task user" do
        @params[:users] << @user.id
        @task.set_users_dependencies_resources(@params, @user)
        @task.save.should == true
        @task.reload
        @task.users.should include(@user)
      end

      it "should saved task without user in database if delete task user" do
        @params[:users] = []
        @params[:assigned] = []
        @task.set_users_dependencies_resources(@params, @user)
        @task.save.should == true
        @task.reload
        @task.users.should == []
      end

      it "should saved new resource in database if add task resource" do
        @task.resource_ids.should_not include(@resource.id)
        @params[:resource][:ids] << @resource.id
        @task.set_users_dependencies_resources(@params, @user)
        @task.save.should == true
        @task.reload
        @task.resources.should include(@resource)
      end
      it "should saved task without resource in database if delete task resource" do
        @params[:resource][:ids] = []
        @task.set_users_dependencies_resources(@params, @user)
        @task.save.should == true
        @task.reload
        @task.resources.should == []
      end
      it "should saved new dependencies if add task dependencies" do
        dependent = TaskRecord.make(:company => @company, :project => @task.project)
        @params[:dependencies] << dependent.task_num.to_s
        @task.set_users_dependencies_resources(@params, @user)
        @task.save.should == true
        @task.reload
        @task.dependencies.should include(dependent)
      end
      it "should saved task without dependency if delete task dependencies" do
        @params[:dependencies]=[]
        @task.set_users_dependencies_resources(@params, @user)
        @task.save.should == true
        @task.reload
        @task.dependencies.should == []
      end

      it "should not change task user in database if not changed task user" do
        user_ids = @task.user_ids
        @params[:resource][:ids] << @resource.id
        @task.set_users_dependencies_resources(@params, @user)
        @task.save.should == true
        @task.reload
        @task.user_ids.should == user_ids
      end
      it "should not change task resource in database if not changed task resource" do
        resource_ids = @task.resource_ids
        @params[:users] << @user.id
        @task.set_users_dependencies_resources(@params, @user)
        @task.save.should == true
        @task.reload
        @task.resource_ids.should == resource_ids
      end
      it "should not change task dependency in database if not changed task dependency" do
        dependency_ids = @task.dependency_ids
        @params[:users] << @user.id
        @params[:resource][:ids] << @resource.id
        @task.set_users_dependencies_resources(@params, @user)
        @task.save.should == true
        @task.reload
        @task.dependency_ids.should == dependency_ids
      end
    end

    context "when task not saved" do

      it "should build new user in memory if add task user" do
        pending
        @params[:users] << @user.id
        @task.set_users_dependencies_resources(@params, @user)
        @task.project_id = nil
        @task.save.should == false
        @task.users.should include(@user)
        @task.reload
        @task.users.should_not include(@user)
      end

      it "should delete exist user from memory if delete task user" do
        pending
        @params[:user] = []
        @params[:assigned] = []
        @task.set_users_dependencies_resources(@params, @user)
        @task.project_id = nil
        @task.save.should == false
        @task.users.should == []
        @task.reload
        @task.users.should_not []
      end

      it "should build new resource in memory if add task resource" do
        pending
        @task.resource_ids.should_not include(@resource.id)
        @params[:resource][:ids] << @resource.id
        @task.set_users_dependencies_resources(@params, @user)
        @task.project_id = nil
        @task.save.should == false
        @task.resources.should include(@resource)
        @task.reload
        @task.resources.should_not include(@resource)
      end

      it "should delete exist resource from memory if delete task resource" do
        pending
        @task.resources.should_not be_empty
        ids= @task.resource_ids
        @params[:resource][:ids] = []
        @task.set_users_dependencies_resources(@params, @user)
        @task.project_id = nil
        @task.save.should == false
        @task.resources.should be_empty
        @task.reload
        @task.resource_ids.should == ids
      end

      it "should build new dependency in memory if add task dependency" do
        pending
        dependent = TaskRecord.make(:company => @company, :project => @task.project)
        @params[:dependencies] << dependent.task_num.to_s
        @task.set_users_dependencies_resources(@params, @user)
        @task.project_id = nil
        @task.save.should == false
        @task.dependencies.should include(dependent)
        @task.reload
        @task.dependencies.should_not include(dependent)
      end
      it "should delete exist dependency from memory if delete task dependency"

      it "should not change task user in database if not change task user"
      it "should not change task resource in database if not change task resource"
      it "should not change task dependency in database if not change task dependency"
    end
  end

  describe "When creating a new task and the project it belongs to have some score rules" do
    before(:each) do
      @score_rule_1 = ScoreRule.make(:score      => 250,
                                     :score_type => ScoreRuleTypes::FIXED)

      @score_rule_2 = ScoreRule.make(:score      => 150,
                                     :score_type => ScoreRuleTypes::FIXED)


      project = Project.make(:score_rules => [@score_rule_1, @score_rule_2])
      @task   = TaskRecord.make(:project => project, :weight_adjustment => 10)
    end

    it "should have the right score" do
      new_score = @task.weight_adjustment + @score_rule_1.score + @score_rule_2.score
      @task.weight.should == new_score
    end
  end

  describe "#snoozed?" do
    context "when the task it's closed" do
      before(:each) do
        @task = TaskRecord.make(:status => TaskRecord::CLOSED)
      end

      it "should return false" do
        @task.snoozed?.should be_false
      end
    end

    context "when the tasks it's not close but it's on snozze" do
      before(:each) do
        @task = TaskRecord.make(:status => TaskRecord::OPEN, :wait_for_customer => true)
      end

      it "should return true" do
        @task.snoozed?.should be_true
      end
    end

    context "when the task is both closed and snozzed" do
      before(:each) do
        @task = TaskRecord.make(:status => TaskRecord::CLOSED, :wait_for_customer => true)
      end

      it "should return true" do
        @task.snoozed?.should be_true
      end
    end

    context "whent the task is not closed and its not snozzed" do
      before(:each) do
        @task = TaskRecord.make(:status => TaskRecord::OPEN)
      end

      it "should return true" do
        @task.snoozed?.should be_false
      end
    end
  end

  describe "when updating a task from a project that have score rules" do
    before(:each) do
      @score_rule = ScoreRule.make(:score      => 250,
                                   :score_type => ScoreRuleTypes::FIXED)

      project = Project.make(:score_rules => [@score_rule])
      @task   = TaskRecord.make(:project => project, :weight_adjustment => 10)
    end

    it "should update the weight accordantly" do
      @task.weight.should == @score_rule.score + @task.weight_adjustment
      new_weight_adjustment = 50
      @task.update_attributes(:weight_adjustment => new_weight_adjustment)
      @task.weight.should == @score_rule.score + new_weight_adjustment
    end

    it "should update the weight accordantly if company disallow use score rule" do
      @task.company.update_attribute(:use_score_rules, false)
      @task.weight.should == @score_rule.score + @task.weight_adjustment
      new_weight_adjustment = 50
      @task.update_attributes(:weight_adjustment => new_weight_adjustment)
      @task.weight.should == new_weight_adjustment
    end
  end

  describe "#score_rules" do
    let(:task)          { TaskRecord.make }
    let(:project)       { Project.make }
    let(:customer)      { Customer.make }
    let(:company)       { Company.make }
    let(:score_rule_1)  { ScoreRule.make }
    let(:score_rule_2)  { ScoreRule.make }
    let(:score_rule_3)  { ScoreRule.make }

    before(:each) do
      project.score_rules  << score_rule_1
      customer.score_rules << score_rule_2
      company.score_rules  << score_rule_3

      task.project = project
      task.company = company
      task.customers << customer
    end

    it "should return all the score rules associated with the task" do
      task.score_rules.should include(score_rule_1)
      task.score_rules.should include(score_rule_2)
      task.score_rules.should include(score_rule_3)
    end
  end
end

# == Schema Information
#
# Table name: tasks
#
#  id                 :integer(4)      not null, primary key
#  name               :string(200)     default(""), not null
#  project_id         :integer(4)      default(0), not null
#  position           :integer(4)      default(0), not null
#  created_at         :datetime        not null
#  due_at             :datetime
#  updated_at         :datetime        not null
#  completed_at       :datetime
#  duration           :integer(4)      default(1)
#  hidden             :integer(4)      default(0)
#  milestone_id       :integer(4)
#  description        :text
#  company_id         :integer(4)
#  priority           :integer(4)      default(0)
#  updated_by_id      :integer(4)
#  severity_id        :integer(4)      default(0)
#  type_id            :integer(4)      default(0)
#  task_num           :integer(4)      default(0)
#  status             :integer(4)      default(0)
#  creator_id         :integer(4)
#  hide_until         :datetime
#  scheduled_at       :datetime
#  scheduled_duration :integer(4)
#  scheduled          :boolean(1)      default(FALSE)
#  worked_minutes     :integer(4)      default(0)
#  type               :string(255)     default("Task")
#  weight             :integer(4)      default(0)
#  weight_adjustment  :integer(4)      default(0)
#  wait_for_customer  :boolean(1)      default(FALSE)
#
# Indexes
#
#  index_tasks_on_type_and_task_num_and_company_id  (type,task_num,company_id) UNIQUE
#  tasks_company_id_index                           (company_id)
#  tasks_due_at_idx                                 (due_at)
#  index_tasks_on_milestone_id                      (milestone_id)
#  tasks_project_completed_index                    (project_id,completed_at)
#  tasks_project_id_index                           (project_id,milestone_id)
#

