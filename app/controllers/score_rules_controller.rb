class ScoreRulesController < ApplicationController

  def index
    project      = Project.find(params[:project_id])
    @score_rules = project.score_rules
  end

  def new
  end
end
