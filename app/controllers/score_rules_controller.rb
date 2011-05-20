class ScoreRulesController < ApplicationController
  include ScoreRulesHelper

  before_filter :get_container
  before_filter :validate_score_rule_id, :only => [:show, :edit, :update, :destroy]
  
  def index
    @score_rules = @container.score_rules
    render :layout => show_layout?
  end

  def show
    render :layout => show_layout?
  end

  def new
    @score_rule = @container.score_rules.new
    render :layout => show_layout?
  end

  def create
    @score_rule = ScoreRule.new(params[:score_rule])

    if @score_rule.valid?
      @container.score_rules << @score_rule

      flash[:success] = 'Score rule created!'
      redirect_to container_score_rules_path(@container), :layout => show_layout?
    else
      render :new, :layout => show_layout?
    end
  end

  def edit
    render :layout => show_layout?
  end

  def update
    @score_rule.update_attributes(params[:score_rule])

    if @score_rule.valid?
      flash[:success] = 'Score rule updated!'
      redirect_to container_score_rules_path(@container), :layout => show_layout?
    else
      render :edit, :layout => show_layout?
    end
  end

  def destroy
    @score_rule.destroy
    flash[:success] = 'Score rule deleted!'
    redirect_to container_score_rules_path(@container), :layout => show_layout?
  end

  private
  
  def show_layout?
    !request.xhr?
  end
end
