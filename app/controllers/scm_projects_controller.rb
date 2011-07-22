# encoding: UTF-8

class ScmProjectsController < ApplicationController
  before_filter :authotize_user_is_admin

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
end
