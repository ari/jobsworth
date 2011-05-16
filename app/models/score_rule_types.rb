module ScoreRuleTypes

  FIXED             = 1
  TASK_AGE          = 2
  LAST_COMMENT_AGE  = 3
  OVERDUE           = 4

  def self.all_score_types
    [FIXED, TASK_AGE, LAST_COMMENT_AGE, OVERDUE] 
  end
end
