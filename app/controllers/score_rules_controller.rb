class ScoreRulesController < ApplicationController
  before_filter :get_container
  before_filter :validate_score_rule_id, :only => [:show, :edit, :update, :destroy]
  
  def index
    @score_rules = @container.score_rules
  end

  def show
  end

  def new
    @score_rule = @container.score_rules.new
  end

  def create
    new_score_rule  = ScoreRule.new(params[:score_rule])
    @score_rule     = @container.add_score_rule(new_score_rule)
    
    if @score_rule.valid?
      flash[:success] = 'Score rule created!'
      # Fix this
      redirect_to root_path
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
      redirect_to root_path
    else
      render :edit 
    end
  end

  def destroy
    @score_rule.destroy
    flash[:success] = 'Score rule deleted!'
    redirect_to root_path
  end

  private
  
  def get_container
    @container = case
      when params[:project_id] then Project.find_by_id(params[:project_id])
    end
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
