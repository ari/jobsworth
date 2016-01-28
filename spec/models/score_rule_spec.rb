require 'spec_helper'

describe ScoreRule do

  describe "validations" do

    before(:each) do
      @score_rule_attrs = ScoreRule.make.attributes.with_indifferent_access.except(:id, :controlled_by_id, :controlled_by_type, :created_at, :updated_at)
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

    it "should reject names that are too long" do
      long_name = 'bananas' * 100
      @score_rule_attrs.merge!(:name => long_name)
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

  describe "associations" do

    before(:each) do
      @score_rule = ScoreRule.make
    end

    it "should have a 'controlled_by' association" do
      @score_rule.should respond_to(:controlled_by)
    end
  end
end


# == Schema Information
#
# Table name: score_rules
#
#  id                 :integer(4)      not null, primary key
#  name               :string(255)
#  score              :integer(4)
#  score_type         :integer(4)
#  exponent           :decimal(5, 2)   default(1.0)
#  controlled_by_id   :integer(4)
#  controlled_by_type :string(255)
#  created_at         :datetime
#  updated_at         :datetime
#
# Indexes
#
#  index_score_rules_on_controlled_by_id  (controlled_by_id)
#  index_score_rules_on_score_type        (score_type)
#

