require 'spec_helper'

describe Project do
  let(:project) { Project.make }

  describe 'associations' do
    it "should have a 'score_rules' association" do
      project.should respond_to(:score_rules)
    end

    it "should fetch the right Score Rule instances" do
      some_score_rule = ScoreRule.make 
      project.score_rules << some_score_rule
      project.score_rules.should include(some_score_rule)
    end
  end

  describe "#default_estimate" do
    it "should have a default_estimate" do
      project.should respond_to(:default_estimate)
    end

    it "should default to 1.0" do
      project.default_estimate.should == 1.0
    end
  end

  describe "validations" do
    it "should require a 'default_estimate'" do
      project.default_estimate = nil
      project.should_not be_valid
    end

    it "should require a numeric value on 'default_estimate'" do
      project.default_estimate = 'lol'
      project.should_not be_valid
    end

    it "should require a number greater or equal to 1.0 on 'default_estimate'" do
      project.default_estimate = -1.0
      project.should_not be_valid
    end
  end

  describe "When adding a new score rule to a project that have tasks" do
    before(:each) do
      @open_task    = Task.make(:status => AbstractTask::OPEN)
      @closed_task  = Task.make(:status => AbstractTask::CLOSED)
      @project      = Project.make(:tasks => [@open_task, @closed_task])
      @score_rule   = ScoreRule.make
    end

    it "should update the score of all the open taks" do
      pending "The project model, for now, doesn't update the score of is taks"
      @project.score_rules << @score_rule
      @open_task.reload
      new_score = @open_task.weight_adjustment + @score_rule.score
      @open_task.weight.should == new_score
    end

    it "should not update the score of any closed task" do
      pending "The project model, for now, doesn't update the score of is taks"
      @project.score_rules << @score_rule
      @closed_task.reload
      calculated_score = @open_task.weight_adjustment + @score_rule.score
      @open_task.weight.should_not == calculated_score
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

