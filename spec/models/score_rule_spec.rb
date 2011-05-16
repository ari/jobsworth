require 'spec_helper'

describe ScoreRule do
  context "validations" do

    before(:each) do
      @score_rule_attrs = { :name       => 'bananas', 
                            :score      => 1000,
                            :exponent   => 1,
                            :score_type => ScoreRuleTypes::FIXED }
    end

    it "should require a name" do
      @score_rule_attrs.delete(:name)
      score_rule = ScoreRule.new(@score_rule_attrs)
      score_rule.should_not be_valid
    end

    it "should require a non empty name" do
      @score_rule_attrs.merge!(:name => '')
      score_rule = ScoreRule.new(@score_rule_attrs)
      score_rule.should_not be_valid 
    end

    it "should require a score"  do
      @score_rule_attrs.delete(:score)
      score_rule = ScoreRule.new(@score_rule_attrs)
      score_rule.should_not be_valid
    end
                                 
    it "should require a non empty score" do
      @score_rule_attrs.merge!(:score => '')
      score_rule = ScoreRule.new(@score_rule_attrs) 
      score_rule.should_not be_valid
    end

    it "should require a numeric score" do
      @score_rule_attrs.merge!(:score => 'lol')
      score_rule = ScoreRule.new(@score_rule_attrs)
      score_rule.should_not be_valid
    end

    it "should require a valid score_type value" do
      @score_rule_attrs.merge!(:score_type => -1)
      score_rule = ScoreRule.new(@score_rule_attrs)
      score_rule.should_not be_valid
    end

    it "should require an exponent" do
      @score_rule_attrs.delete(:exponent)
      score_rule = ScoreRule.new(@score_rule_attrs)
      score_rule.should_not be_valid
    end
  end

  context "associations" do
  end
end
