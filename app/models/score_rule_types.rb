module ScoreRuleTypes
  FIXED             = 1
  TASK_AGE          = 2
  LAST_COMMENT_AGE  = 3
  OVERDUE           = 4

  def self.all_score_types
    [FIXED, TASK_AGE, LAST_COMMENT_AGE, OVERDUE]
  end

  def self.to_select_list
    { I18n.t("score_rule_types.fixed")            => FIXED,
      I18n.t("score_rule_types.task_age")         => TASK_AGE,
      I18n.t("score_rule_types.last_comment_age") => LAST_COMMENT_AGE,
      I18n.t("score_rule_types.overdue")          => OVERDUE }
  end

  def self.get_name_of(score_rule_type)
    case score_rule_type
      when FIXED              then I18n.t("score_rule_types.fixed")
      when TASK_AGE           then I18n.t("score_rule_types.task_age")
      when LAST_COMMENT_AGE   then I18n.t("score_rule_types.last_comment_age")
      when OVERDUE            then I18n.t("score_rule_types.overdue")
    end
  end
end
