require 'spec_helper'

describe Company do

  describe "associations" do
    before(:each) do
      @score_rule_1 = ScoreRule.make
      @score_rule_2 = ScoreRule.make
      @company      = Company.make(:score_rules => [@score_rule_1, @score_rule_2])
    end

    it "should have a 'score_rules' association" do
      @company.should respond_to(:score_rules)
    end

    it "should fetch the right 'score_rules' from the association" do
      @company.score_rules.should include(@score_rule_1)
      @company.score_rules.should include(@score_rule_2)
    end
  end

  describe "#add_score_rule" do
    before(:each) do
      @company    = Company.make
      @old_weight = 50
      @task       = Task.make(:company            => @company,
                              :weight_adjustment  => @old_weight)
      @score_rule = ScoreRule.make(:score => 100)
    end

    context "when adding a new score rule" do
      it "should add the score to the 'score_rules' association" do
        @company.add_score_rule(@score_rule) 
        @company.score_rules.should include(@score_rule)
      end
      
      it "should update the score of all the task that belong to the company" do
        @company.add_score_rule(@score_rule)
        @task.reload
        @task.weight_adjustment.should == @old_weight + @score_rule.score
      end
    end
  end
end
