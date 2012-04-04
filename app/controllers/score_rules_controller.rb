class ScoreRulesController < ApplicationController
  include ScoreRulesHelper

  before_filter :get_container
  before_filter :validate_score_rule_id, :only => [:show, :edit, :update, :destroy]

  layout :false
  
  def index
    @score_rules = @container.score_rules
  end

  def show
  end

  def new
    @score_rule = @container.score_rules.new
  end

  def create
    @score_rule = ScoreRule.new(params[:score_rule])

    if @score_rule.valid?
      @container.score_rules << @score_rule

      flash[:success] = 'Score rule created!'
      redirect_to container_score_rules_path(@container)
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
      redirect_to container_score_rules_path(@container)
    else
      render :edit
    end
  end

  def destroy
    @score_rule.destroy
    flash[:success] = 'Score rule deleted!'

    # Note: a DELETE request redirect(302) will regenerate a new DELETE request to the new URL
    # Setting status to 302 is a walkaround
    #
    # Read more: http://softwareas.com/the-weirdness-of-ajax-redirects-some-workarounds
    redirect_to container_score_rules_path(@container), :status => 303
  end
end
