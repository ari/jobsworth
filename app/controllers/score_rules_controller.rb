class ScoreRulesController < ApplicationController
  include ScoreRulesHelper

  before_filter :get_container
  before_filter :validate_score_rule_id, :only => [:show, :edit, :update, :destroy]
  
  def index
    @score_rules = @container.score_rules
    render :layout => false if request.xhr?
  end

  def show
  end

  def new
    @score_rule = @container.score_rules.new
    render :layout => false if request.xhr?
  end

  def create
    new_score_rule  = ScoreRule.new(params[:score_rule])
    @score_rule     = @container.add_score_rule(new_score_rule)
    
    if @score_rule.valid?
      flash[:success] = 'Score rule created!'
      if request.xhr?
        redirect_to project_score_rules_path(@container), :layout => false
      else
        redirect_to project_score_rules_path(@container)
      end
    else
      if request.xhr?
        render :new, :layout => false
      else
        render :new
      end
    end
  end

  def edit
    render :layout => false if request.xhr?
  end

  def update
    @score_rule.update_attributes(params[:score_rule])

    if @score_rule.valid?
      flash[:success] = 'Score rule updated!'
      if request.xhr?
        redirect_to project_score_rules_path(@container), :layout => false
      else
        redirect_to project_score_rules_path(@container)
      end    
    else
      if request.xhr?
        render :edit, :layout => false
      else
        render :edit
      end 
    end
  end

  def destroy
    @score_rule.destroy
    flash[:success] = 'Score rule deleted!'
    if request.xhr?
      redirect_to project_score_rules_path(@container), :layout => false
    else
      redirect_to project_score_rules_path(@container)
    end
  end
end
