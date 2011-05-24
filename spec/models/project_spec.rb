require 'spec_helper'

describe Project do
  describe 'associations' do
    let(:project) { Project.make }

    it "should have a 'score_rules' association" do
      project.should respond_to(:score_rules)
    end

    it "should fetch the right Score Rule instances" do
      some_score_rule = ScoreRule.make 
      project.score_rules << some_score_rule
      project.score_rules.should include(some_score_rule)
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
