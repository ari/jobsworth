class ScoreRulesController < ApplicationController

  def index
    project      = Project.find(params[:project_id])
    @score_rules = project.score_rules
  end

  def new
    project     = Project.find(params[:project_id])
    @score_rule = project.score_rules.new
  end

  def create
    project_id  = params[:project_id]
    project     = Project.find(project_id)
    @score_rule = project.score_rules.new(params[:score_rule])
    
    if @score_rule.valid?
      @score_rule.save
      flash[:success] = 'Score rule created!'
      redirect_to score_rules_path(project_id)
    else
      render :new
    end
  end

  def edit
  end
end
