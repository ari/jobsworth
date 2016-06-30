require 'spec_helper'

describe Project do
  let(:project) { Project.make }

  describe 'associations' do
    it "should have a 'score_rules' association" do
      expect(project).to respond_to(:score_rules)
    end

    it 'should fetch the right Score Rule instances' do
      some_score_rule = ScoreRule.make
      project.score_rules << some_score_rule
      expect(project.score_rules).to include(some_score_rule)
    end
  end

  describe '#default_estimate' do
    it 'should have a default_estimate' do
      expect(project).to respond_to(:default_estimate)
    end

    it 'should default to 1.0' do
      expect(project.default_estimate).to eq(1.0)
    end
  end

  describe 'validations' do
    it "should require a 'default_estimate'" do
      project.default_estimate = nil
      expect(project).not_to be_valid
    end

    it "should require a numeric value on 'default_estimate'" do
      project.default_estimate = 'lol'
      expect(project).not_to be_valid
    end

    it "should require a number greater or equal to 1.0 on 'default_estimate'" do
      project.default_estimate = -1.0
      expect(project).not_to be_valid
    end
  end

  describe '#billing_enabled?' do
    subject { FactoryGirl.create(:project) }

    it 'should return true if company allows billing use' do
      subject.company.use_billing = true
      expect(subject.billing_enabled?).to be_truthy
    end

    it "should return false if company doesn't allow billing use" do
      subject.company.use_billing = false
      expect(subject.billing_enabled?).to be_falsey
    end
  end

  describe 'When adding a new score rule to a project that have tasks' do
    before(:each) do
      @open_task = TaskRecord.make(:status => AbstractTask::OPEN)
      @closed_task = TaskRecord.make(:status => AbstractTask::CLOSED)
      @project = Project.make(:tasks => [@open_task, @closed_task])
      @score_rule = ScoreRule.make
    end

    it 'should update the score of all the open taks' do
      skip "The project model, for now, doesn't update the score of is taks"
      @project.score_rules << @score_rule
      @open_task.reload
      new_score = @open_task.weight_adjustment + @score_rule.score
      expect(@open_task.weight).to eq(new_score)
    end

    it 'should not update the score of any closed task' do
      skip "The project model, for now, doesn't update the score of is taks"
      @project.score_rules << @score_rule
      @closed_task.reload
      calculated_score = @open_task.weight_adjustment + @score_rule.score
      expect(@open_task.weight).not_to eq(calculated_score)
    end
  end
end


# == Schema Information
#
# Table name: projects
#
#  id               :integer(4)      not null, primary key
#  name             :string(200)     default(""), not null
#  company_id       :integer(4)      default(0), not null
#  customer_id      :integer(4)      default(0), not null
#  created_at       :datetime
#  updated_at       :datetime
#  completed_at     :datetime
#  critical_count   :integer(4)      default(0)
#  normal_count     :integer(4)      default(0)
#  low_count        :integer(4)      default(0)
#  description      :text
#  open_tasks       :integer(4)
#  total_tasks      :integer(4)
#  total_milestones :integer(4)
#  open_milestones  :integer(4)
#  default_estimate :decimal(5, 2)   default(1.0)
#  neverBill        :boolean(1)
#
# Indexes
#
#  projects_company_id_index   (company_id)
#  projects_customer_id_index  (customer_id)
#

