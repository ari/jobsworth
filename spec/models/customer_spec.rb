require 'spec_helper'

describe Customer do
  describe 'associations' do
    let(:customer) { Customer.make }

    it "should have a 'score_rules' association" do
      expect(customer).to respond_to(:score_rules)
    end

    it "should fetch the right Score Rule instances" do
      some_score_rule = ScoreRule.make
      customer.score_rules << some_score_rule
      expect(customer.score_rules).to include(some_score_rule)
    end
  end

  describe "When adding a new score rule to a customer that have tasks" do
    before(:each) do
      @open_task    = TaskRecord.make(:status => AbstractTask::OPEN)
      @closed_task  = TaskRecord.make(:status => AbstractTask::CLOSED)
      @customer     = Customer.make(:tasks => [@open_task, @closed_task])
      @score_rule   = ScoreRule.make
    end

    it "should update the score of all the open taks" do
      skip "The customer model, for now, doesn't update the score of is taks"
      @customer.score_rules << @score_rule
      @open_task.reload
      new_score = @open_task.weight_adjustment + @score_rule.score
      expect(@open_task.weight).to eq(new_score)
    end

    it "should not update the score of any closed task" do
      skip "The customer model, for now, doesn't update the score of is taks"
      @customer.score_rules << @score_rule
      @closed_task.reload
      calculated_score = @open_task.weight_adjustment + @score_rule.score
      expect(@closed_task.weight).not_to eq(calculated_score)
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

