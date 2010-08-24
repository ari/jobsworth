
class ScmProjectsController < ApplicationController
  before_filter :check_access

  def new
    @scm_project= ScmProject.new
  end

  def create
    @scm_project= ScmProject.new(params[:scm_project])
    @scm_project.company= current_user.company
    if @scm_project.save
      redirect_to scm_project_url(@scm_project)
    else
      render :action=>:new
    end
  end

  def show
    @scm_project=ScmProject.find(params[:id])
  end

private
  def check_access
    unless current_user.admin?
      flash['notice'] = _"You're not allowed to create new scm project. Have your admin give you access."
      redirect_from_last
      return false
    end
  end
end
