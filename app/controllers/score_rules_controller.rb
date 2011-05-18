class ScoreRulesController < ApplicationController
  before_filter :validate_project_id  
  
  def index
    @score_rules = @project.score_rules
  end

  def new
    @score_rule = @project.score_rules.new
  end

  def create
    @score_rule = @project.score_rules.new(params[:score_rule])
    
    if @score_rule.valid?
      @score_rule.save
      flash[:success] = 'Score rule created!'
      redirect_to score_rules_path(params[:project_id])
    else
      render :new
    end
  end

  def edit
    @score_rule = @project.score_rules.find(params[:id])
  end

  def update
    @score_rule  = @project.score_rules.find(params[:id])
    @score_rule.update_attributes(params[:score_rule])

    if @score_rule.valid?
      flash[:success] = 'Score rule updated!'
      redirect_to score_rules_path(params[:project_id])
    else
      render :edit 
    end
  end

  def destroy
    @score_rule  = @project.score_rules.find(params[:id])
    @score_rule.destroy
    flash[:success] = 'Score rule deleted'
    redirect_to score_rules_path(params[:project_id])
  end

  private

  def validate_project_id
    @project = Project.find_by_id(params[:project_id])

    unless @project 
      redirect_to projects_path
      flash[:error] = 'Invalid project id'
    end
  end

end
