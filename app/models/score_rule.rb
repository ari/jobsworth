class ScoreRule < ActiveRecord::Base
  include ScoreRuleTypes

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
  

  def calculate_score_for(task)
    case score_type
      when FIXED then score
      # Must know what's the age of a task (the since it was created? or the hours worked?)
      when TASK_AGE then score
      # There's no comment entity at the momment.
      when LAST_COMMENT_AGE then score 
      # Must define an algo for this scenario
      when OVERDUE then score
    end
  end

end
