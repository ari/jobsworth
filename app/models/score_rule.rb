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
      when FIXED then 
        score
      when TASK_AGE then 
        # If the task is 'brand new' created_at should be nil, this code sets
        # a default value for it.
        task_created_at = (task.created_at.nil?) ? Time.now.utc : task.created_at

        task_age = (Time.now.utc - task_created_at).days
        score * (task_age ** exponent)
      when LAST_COMMENT_AGE then
        # Set last_comment_started to a default value (in case the task doesn't 
        # have comments)
        last_comment_started_at = Time.now.utc

        if task.work_logs.any? and not task.work_logs.last.started_at.nil?
          last_comment_started_at = task.work_logs.last.started_at
        end

        last_comment_age = (Time.now.utc - last_comment_started_at).days
        score * (last_comment_age ** exponent)
    end
  end
end
