module ScoreRuleTypes
  FIXED             = 1
  TASK_AGE          = 2
  LAST_COMMENT_AGE  = 3

  def self.all_score_types
    [FIXED, TASK_AGE, LAST_COMMENT_AGE] 
  end

  def self.to_select_list
    { 'Fixed'             => FIXED, 
      'Task Age'          => TASK_AGE,
      'Last Comment Age'  => LAST_COMMENT_AGE }
  end
end
