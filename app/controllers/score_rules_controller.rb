class ScoreRulesController < ApplicationController
  before_filter :validate_project_id
  before_filter :validate_score_rule_id, :only => [:edit, :update, :destroy]
  
  def index
    @score_rules = @project.score_rules
  end

  def new
    @score_rule = @project.score_rules.new
  end

  def create
    @score_rule = @project.score_rules.create(params[:score_rule])
    
    if @score_rule.valid?
      flash[:success] = 'Score rule created!'
      redirect_to project_score_rules_path(params[:project_id])
    else
      render :new
    end
  end

  def edit
  end

  def update
    @score_rule.update_attributes(params[:score_rule])

    if @score_rule.valid?
      flash[:success] = 'Score rule updated!'
      redirect_to score_rules_path(params[:project_id])
    else
      render :edit 
    end
  end

  def destroy
    @score_rule.destroy
    flash[:success] = 'Score rule deleted!'
    redirect_to score_rules_path(params[:project_id])
  end

  private

  def validate_project_id
    @project = Project.find_by_id(params[:project_id])
    redirect_with_error 'Invalid project id' unless @project
  end

  def validate_score_rule_id
    @score_rule  = @project.score_rules.find_by_id(params[:id])
    redirect_with_error 'Invalid score rule id' unless @score_rule
  end

  def redirect_with_error(error_msg)
    redirect_to projects_path
    flash[:error] = error_msg
  end
end
