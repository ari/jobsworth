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
end
