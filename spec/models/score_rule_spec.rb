require 'spec_helper'

describe ScoreRule do

  describe "validations" do

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

  describe "#update_score_with" do

    context "when the score type is of type FIXED" do

      let(:score_rule)  { ScoreRule.make(:score_type => ScoreRuleTypes::FIXED) }
      let(:task)        { Task.make }

      it "should update the task score accordingly" do
        task.update_score_with(score_rule)
        task.weight.should == score_rule.score + task.weight_adjustment
      end
    end    

    context "when the score type is of type TASK_AGE" do

      let(:score_rule)  { ScoreRule.make(:score_type => ScoreRuleTypes::TASK_AGE) }
      let(:task)        { Task.make }

      it "should change the task score accordingly if the task its brand new" do
        task_age = (Time.now.utc.to_date - task.created_at.to_date).to_f
        
        calculated_score = score_rule.score * (task_age ** score_rule.exponent)

        task.update_score_with(score_rule)
        task.weight.should == task.weight_adjustment + calculated_score.to_i
      end

      it "should change the task score accordingly if the task its not brand new" do
        task.update_attributes(:created_at => Time.now.utc - 2.day)

        task_age = (Time.now.utc.to_date - task.created_at.to_date).to_f
        calculated_score = score_rule.score * (task_age ** score_rule.exponent)

        task.update_score_with(score_rule)
        task.weight.should == task.weight_adjustment + calculated_score.to_i
      end
    end

    context "when the score type is of type LAST_COMMENT_AGE" do

      let(:score_rule)  { ScoreRule.make(:score_type => ScoreRuleTypes::LAST_COMMENT_AGE) }
      let(:task)        { Task.make }

      context "and the task doesn't have any comments" do
        it "should not change the task score" do
          expect {
            task.update_score_with(score_rule)
          }.to_not change { task.weight }
        end
      end

      context "and the task have some comments" do
        before(:each) do
          @new_comment_1 = WorkLog.make(:started_at => Time.now.utc - 3.days, 
                                        :customer   => task.customers.first)

          @new_comment_2 = WorkLog.make(:started_at => Time.now.utc - 2.days, 
                                        :customer   => task.customers.first)
          task.work_logs << @new_comment_2 
          task.work_logs << @new_comment_1 
        end

        it "should change the task score accordingly" do 
          last_comment_age = (Time.now.utc.to_date - @new_comment_2.started_at.to_date).to_f
          calculated_score = score_rule.score * (last_comment_age ** score_rule.exponent)
          task.update_score_with(score_rule)
          task.weight.should == task.weight_adjustment + calculated_score.to_i
        end
      end
    end

    context "when the score type is of type OVERDUE" do

      let(:score_rule)  { ScoreRule.make(:score_type => ScoreRuleTypes::OVERDUE) }
      let(:task)        { Task.make }

      context "and the task is not past due" do
        it "should not change the task score" do
          expect {
            task.update_score_with(score_rule)
          }.to_not change { task.weight }
        end
      end

      context "when the task has an assigned target date" do
        context "and the task its pass due" do
          it "should change the task score accordingly using the target date" do 
            task.update_attributes(:due_at => Time.now.utc + 3.days)
            task_due_age = (Time.now.utc.to_date - task.due_at.to_date).to_f 

            calculated_score = score_rule.score * (task_due_age.abs ** score_rule.exponent)
            calculated_score = -calculated_score if task_due_age < 0
            task.update_score_with(score_rule)
            task.weight.should == task.weight_adjustment + calculated_score.to_i
          end
        end   
      end

      context "when the task doesn't have an assigned target date" do
        context "and has a milestone" do
          context "and the task its pass due" do
            it "should change the task score accordingly" do 
              task.update_attributes(:due_at => nil)
              milestone =  Milestone.make(:company => task.company, 
                                          :project => task.project,
                                          :due_at  => Time.now.utc - 2.days)

              task.milestone = milestone
              task_due_age = (Time.now.utc.to_date - milestone.due_at.to_date).to_f 

              calculated_score = score_rule.score * (task_due_age.abs ** score_rule.exponent)
              calculated_score = -calculated_score if task_due_age < 0
              task.update_score_with(score_rule)
              task.weight.should == task.weight_adjustment + calculated_score.to_i
            end
          end   
        end
      end
      
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

