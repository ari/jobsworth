require 'spec_helper'

describe Company do
  describe 'sole company' do
    before(:each) do
      Company.destroy_all
      @company = Company.make
    end

    it 'should return the first Company if only one is present' do
      expect(Company.sole_company).to eq(@company)
    end

    it 'should not return any Company if multiple are present' do
      Company.make
      expect(Company.sole_company).to be_nil
    end
  end

  describe 'associations' do
    before(:each) do
      @score_rule_1 = ScoreRule.make
      @score_rule_2 = ScoreRule.make
      @company      = Company.make(:score_rules => [@score_rule_1, @score_rule_2])
    end

    it "should have a 'score_rules' association" do
      expect(@company).to respond_to(:score_rules)
    end

    it "should fetch the right 'score_rules' from the association" do
      expect(@company.score_rules).to include(@score_rule_1)
      expect(@company.score_rules).to include(@score_rule_2)
    end
  end

  describe 'When adding a new score rule to a company that have tasks' do
    before(:each) do
      @open_task    = TaskRecord.make(:status => AbstractTask::OPEN)
      @open_task.update_attributes(:task_num => 10)
      @closed_task  = TaskRecord.make(:status => AbstractTask::CLOSED)
      @company      = Company.make(:tasks => [@open_task, @closed_task])
      @score_rule   = ScoreRule.make
    end

    it 'should update the score of all the open taks' do
      skip "The company model, for now, doesn't update the score of is taks"
      @company.score_rules << @score_rule
      @open_task.reload
      new_score = @open_task.weight_adjustment + @score_rule.score
      expect(@open_task.weight).to eq(new_score)
    end

    it 'should not update the score of any closed task' do
      skip "The company model, for now, doesn't update the score of is taks"
      @company.score_rules << @score_rule
      @closed_task.reload
      calculated_score = @open_task.weight_adjustment + @score_rule.score
      expect(@open_task.weight).not_to eq(calculated_score)
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

