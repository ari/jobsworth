module ScoreRuleTypes
  FIXED             = 1
  TASK_AGE          = 2
  LAST_COMMENT_AGE  = 3
  OVERDUE           = 4

  def self.all_score_types
    [FIXED, TASK_AGE, LAST_COMMENT_AGE, OVERDUE] 
  end

  def self.to_select_list
    { 'Fixed score'                               => FIXED, 
      'Score per day since creation'              => TASK_AGE,
      'Score per day since last public comment'   => LAST_COMMENT_AGE,
      'Score per day overdue'                     => OVERDUE }
  end

  def self.get_name_of(score_rule_type)
    case score_rule_type
      when FIXED              then 'Fixed score'
      when TASK_AGE           then 'Score per day since creation'
      when LAST_COMMENT_AGE   then 'Score per day since last public comment'
      when OVERDUE            then 'Score per day overdue'
    end
  end
end
