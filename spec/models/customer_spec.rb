require 'spec_helper'

describe Customer do
  describe 'associations' do
    let(:customer) { Customer.make }

    it "should have a 'score_rules' association" do
      customer.should respond_to(:score_rules)
    end

    it "should fetch the right Score Rule instances" do
      some_score_rule = ScoreRule.make 
      customer.score_rules << some_score_rule
      customer.score_rules.should include(some_score_rule)
    end
  end

  describe "When adding a new score rule to a customer that have tasks" do
    before(:each) do
      @open_task    = Task.make(:status => AbstractTask::OPEN)
      @closed_task  = Task.make(:status => AbstractTask::CLOSED)
      @customer     = Customer.make(:tasks => [@open_task, @closed_task])
      @score_rule   = ScoreRule.make
    end

    it "should update the score of all the open taks" do
      pending "The customer model, for now, doesn't update the score of is taks"
      @customer.score_rules << @score_rule
      @open_task.reload
      new_score = @open_task.weight_adjustment + @score_rule.score
      @open_task.weight.should == new_score
    end

    it "should not update the score of any closed task" do
      pending "The customer model, for now, doesn't update the score of is taks"
      @customer.score_rules << @score_rule
      @closed_task.reload
      calculated_score = @open_task.weight_adjustment + @score_rule.score
      @closed_task.weight.should_not == calculated_score
    end 
  end
end


# == Schema Information
#
# Table name: customers
#
#  id           :integer(4)      not null, primary key
#  company_id   :integer(4)      default(0), not null
#  name         :string(200)     default(""), not null
#  contact_name :string(200)
#  created_at   :datetime
#  updated_at   :datetime
#  active       :boolean(1)      default(TRUE)
#
# Indexes
#
#  customers_company_id_index  (company_id,name)
#

