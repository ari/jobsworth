class ScoreRule < ActiveRecord::Base
  attr_accessible(:name, :score, :score_type, :exponent)

  belongs_to :controlled_by, 
             :polymorphic => true

  validates :exponent,
            :presence => true

  validates :name, 
            :presence => true

  validates :score, 
            :presence     => true, 
            :numericality => true

  validates :score_type,
            :presence  => true,
            :inclusion => { :in => ScoreRuleTypes::all_score_types }
  
end
