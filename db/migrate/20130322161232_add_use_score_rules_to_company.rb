class AddUseScoreRulesToCompany < ActiveRecord::Migration
  def change
    add_column :companies, :use_score_rules, :boolean, :default => true
  end
end
