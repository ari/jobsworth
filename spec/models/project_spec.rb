require 'spec_helper'

describe Project do

  context 'associations' do

    before(:each) do
      @project = Project.make
    end

    it "should have a 'score_rules' association" do
      @project.should respond_to(:score_rules)
    end

    it "should fetch the right Score Rule instances" do
      some_score_rule = ScoreRule.make 
      @project.score_rules << some_score_rule
      @project.score_rules.should include(some_score_rule)
    end
  end

  describe "#add_score_rule" do
    describe "when adding a new score rule" do
      before(:each) do
        @project    = Project.make
        @old_weight = 50
        @task       = Task.make(:project            => @project, 
                                :weight_adjustment  => @old_weight)
      end
  
      it "should update the score of all the project's tasks" do
        new_score_rule = ScoreRule.make(:score => 100)
        @project.add_score_rule(new_score_rule)
        @task.reload
        @task.weight_adjustment.should == (@old_weight + new_score_rule.score)
      end
    end
  end
end
