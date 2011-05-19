class ScoreRulesController < ApplicationController
  include ScoreRulesHelper

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
end
