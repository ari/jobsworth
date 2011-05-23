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
    score_adjustment = task.weight_adjustment

    case score_type
      when FIXED then 
        score + score_adjustment
      when TASK_AGE then 
        task_age = (Time.now.utc - task.created_at).days
        score_adjustment + score * (task_age ** exponent)
      when LAST_COMMENT_AGE then
        last_comment     = task.work_logs.last
        last_comment_age = (Time.now.utc - last_comment.created_at).days
        score_adjustment + score * (last_comment_age ** exponent)
    end
  end
end
