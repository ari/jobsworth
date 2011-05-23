require 'spec_helper'

describe ScoreRule do
  context "validations" do

    before(:each) do
      @score_rule_attrs = ScoreRule.make.attributes
    end

    it "should require a name" do
      @score_rule_attrs.delete('name')
      score_rule = ScoreRule.new(@score_rule_attrs)
      score_rule.should_not be_valid
    end

    it "should require a non empty name" do
      @score_rule_attrs.merge!('name' => '')
      score_rule = ScoreRule.new(@score_rule_attrs)
      score_rule.should_not be_valid 
    end

    it "should require a score"  do
      @score_rule_attrs.delete('score')
      score_rule = ScoreRule.new(@score_rule_attrs)
      score_rule.should_not be_valid
    end
                                 
    it "should require a non empty score" do
      @score_rule_attrs.merge!('score' => '')
      score_rule = ScoreRule.new(@score_rule_attrs) 
      score_rule.should_not be_valid
    end

    it "should require a numeric score" do
      @score_rule_attrs.merge!('score' => 'lol')
      score_rule = ScoreRule.new(@score_rule_attrs)
      score_rule.should_not be_valid
    end

    it "should require a valid score_type value" do
      @score_rule_attrs.merge!('score_type' => -1)
      score_rule = ScoreRule.new(@score_rule_attrs)
      score_rule.should_not be_valid
    end

    it "should have a default exponent" do
      @score_rule_attrs.delete('exponent')
      score_rule = ScoreRule.new(@score_rule_attrs)
      score_rule.exponent.should == 1
    end
  end

  context "associations" do

    before(:each) do
      @score_rule = ScoreRule.make  
    end

    it "should have a 'controlled_by' association" do
      @score_rule.should respond_to(:controlled_by)   
    end
  end
end
