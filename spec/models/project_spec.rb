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
end
