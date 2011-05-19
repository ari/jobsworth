module ScoreRulesHelper
  def score_rules_path_for(container)
    case container.class.to_s
      when 'Project' then project_score_rules_path(container)
      when 'Company' then company_score_rules_path(container)
    end
  end

  def score_rule_path_for(container, score_rule)
    case container.class.to_s
      when 'Project' then project_score_rule_path(container, score_rule)
      when 'Company' then company_score_rule_path(container, score_rule)
    end
end

  def edit_score_rule_path_for(container, score_rule)
    case container.class.to_s
      when 'Project' then edit_project_score_rule_path(container, score_rule)
      when 'Company' then edit_company_score_rule_path(container, score_rule)
    end
  end
end
