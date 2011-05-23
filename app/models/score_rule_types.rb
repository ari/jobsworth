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

  def self.get_name_of(score_rule_type)
    case score_rule_type
      when FIXED then 'Fixed'
      when TASK_AGE then 'Task Age'
      when 'LAST_COMMENT_AGE' then 'Last Comment Age'
    end
  end
end
