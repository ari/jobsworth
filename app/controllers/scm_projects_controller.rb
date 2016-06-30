# encoding: UTF-8

class ScmProjectsController < ApplicationController
  before_filter :authorize_user_is_admin

  def new
    @scm_project= ScmProject.new
  end

  def create
    @scm_project= ScmProject.new(scm_project_params)
    @scm_project.company= current_user.company
    if @scm_project.save
      flash[:success] = t('flash.notice.model_created', model: Project.model_name.human)
      redirect_to scm_project_url(@scm_project)
    else
      flash[:error] = @scm_project.errors.full_messages.join('. ')
      render :action => :new
    end
  end

  def show
    @scm_project=ScmProject.find(params[:id])
  end

  private

  def scm_project_params
    params.require(:scm_project).permit(:scm_type, :location)
  end
end
