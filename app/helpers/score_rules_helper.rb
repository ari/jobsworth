module ScoreRulesHelper

  ###
  # The following methods will define the routes
  # used by the Score Rules resources based on the class of
  # it's container.

  def container_score_rules_path(container)
    container_class_name = container.class.to_s.underscore.downcase
    eval "#{container_class_name}_score_rules_path(container)"
  end

  def container_score_rule_path(container, score_rule)
    container_class_name = container.class.to_s.underscore.downcase
    eval "#{container_class_name}_score_rule_path(container, score_rule)"
  end

  def new_container_score_rule_path(container)
    container_class_name = container.class.to_s.underscore.downcase
    eval "new_#{container_class_name}_score_rule_path(container)"
  end

  def edit_container_score_rule_path(container, score_rule)
    container_class_name = container.class.to_s.underscore.downcase
    eval "edit_#{container_class_name}_score_rule_path(container, score_rule)"
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
    container_class   = eval(container_id_key.humanize.titleize.delete(' '))
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
