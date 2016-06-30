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
    @score_rule = ScoreRule.new(score_rule_params)

    if @score_rule.valid?
      @container.score_rules << @score_rule

      flash[:success] = t('flash.notice.model_created', model: ScoreRule.model_name.human)
      redirect_to container_score_rules_path(@container)
    else
      render :new
    end
  end

  def edit
  end

  def update
    @score_rule.update_attributes(score_rule_params)

    if @score_rule.valid?
      flash[:success] = t('flash.notice.model_updated', model: ScoreRule.model_name.human)
      redirect_to container_score_rules_path(@container)
    else
      render :edit
    end
  end

  def destroy
    @score_rule.destroy
    flash[:success] = t('flash.notice.model_deleted', model: ScoreRule.model_name.human)

    # Note: a DELETE request redirect(302) will regenerate a new DELETE request to the new URL
    # Setting status to 302 is a walkaround
    #
    # Read more: http://softwareas.com/the-weirdness-of-ajax-redirects-some-workarounds
    redirect_to container_score_rules_path(@container), :status => 303
  end

  private

  def score_rule_params
    params.require(:score_rule).permit :name, :score, :exponent, :score_type
  end
end
