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

  private

  ###
  # This method will parse the params passed with the url and
  # fetch the instance that will work as the 'container' for the score rule
  # (the container will be the model that will hold the score rule)
  # For example, if I have the following url: 
  #    /projects/1/score_rules/new
  #  @container will be set to the project whose id is 1 
  def get_container
    container_id_key  = params.keys.find_all { |key| key =~ /\w+_id/ }.last
    container_class   = eval(container_id_key.gsub(/_id/, '').capitalize)
    @container        = container_class.find_by_id(params[container_id_key])
    redirect_with_error 'Invalid project id' unless @container
  end

  def validate_score_rule_id
    @score_rule  = @container.score_rules.find_by_id(params[:id])
    redirect_with_error 'Invalid score rule id' unless @score_rule
  end

  def redirect_with_error(error_msg)
    redirect_to root_path
    flash[:error] = error_msg
  end
end
