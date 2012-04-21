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

  describe "When adding a new score rule to a company that have tasks" do
    before(:each) do
      @open_task    = Task.make(:status => AbstractTask::OPEN)
      @open_task.update_attributes(:task_num => 10)
      @closed_task  = Task.make(:status => AbstractTask::CLOSED)
      @company      = Company.make(:tasks => [@open_task, @closed_task])
      @score_rule   = ScoreRule.make
    end

    it "should update the score of all the open taks" do
      pending "The company model, for now, doesn't update the score of is taks"
      @company.score_rules << @score_rule
      @open_task.reload
      new_score = @open_task.weight_adjustment + @score_rule.score
      @open_task.weight.should == new_score
    end

    it "should not update the score of any closed task" do
      pending "The company model, for now, doesn't update the score of is taks"
      @company.score_rules << @score_rule
      @closed_task.reload
      calculated_score = @open_task.weight_adjustment + @score_rule.score
      @open_task.weight.should_not == calculated_score
    end 
  end
end


# == Schema Information
#
# Table name: companies
#
#  id                         :integer(4)      not null, primary key
#  name                       :string(200)     default(""), not null
#  contact_email              :string(200)
#  contact_name               :string(200)
#  created_at                 :datetime
#  updated_at                 :datetime
#  subdomain                  :string(255)     default(""), not null
#  show_wiki                  :boolean(1)      default(TRUE)
#  suppressed_email_addresses :string(255)
#  logo_file_name             :string(255)
#  logo_content_type          :string(255)
#  logo_file_size             :integer(4)
#  logo_updated_at            :datetime
#
# Indexes
#
#  index_companies_on_subdomain  (subdomain) UNIQUE
#

