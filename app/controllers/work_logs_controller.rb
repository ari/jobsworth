# encoding: UTF-8

class WorkLogsController < ApplicationController

  before_filter :load_log, :only => [ :edit, :update, :destroy ]
  before_filter :load_task_and_build_log, :only => [ :new, :create ]

  include WorkLogsHelper

  def new
  end

  def create
    @log.user = current_user
    @log.project = @task.project

    if @log.save
      flash[:success] = t('flash.notice.model_created', model: WorkLog.model_name.human)
      redirect_to tasks_path
    else
      flash[:error] = @log.errors.full_messages.join('. ')
      render :new
    end
  end

  def edit
  end

  def update
    @log.attributes = work_log_params
    @log.project = @task.project

    if @log.save
      flash[:success] = t('flash.notice.model_saved', model: WorkLog.model_name.human)
      redirect_to tasks_path
    else
      flash[:error] = @log.errors.full_messages.join('. ')
      render :edit
    end
  end

  def destroy
    if can_delete_log?(@log)
      @log.destroy
      flash[:success] = t('flash.notice.model_deleted', model: WorkLog.model_name.human)
    else
      flash[:error] = t('flash.alert.access_denied_to_model', model: WorkLog.model_name.human)
    end

    redirect_to tasks_path
  end

  def update_work_log
    unless current_user.can_approve_work_logs?
      render :nothing => true
      return false
    end

    log = WorkLog.accessed_by(current_user).find(params[:id])
    log.status= params[:work_log][:status]

    render :text => log.save.to_s
  end

  private

    # Loads the log using the given params
    def load_log
      @log = WorkLog.all_accessed_by(current_user).find(params[:id])
      @task = @log.task
    end

    # Loads the task new logs should be linked to
    def load_task_and_build_log
      @task = current_user.company.tasks.find_by(:task_num => params[:task_id])
      @log  = current_user.company.work_logs.build(work_log_params)
      @log.task = @task
      @log.started_at = Time.now.utc - @log.duration
    end

    def work_log_params
      params.fetch(:work_log, {}).permit(:started_at, :customer_id, :duration, :body, :access_level_id,
        :set_custom_attribute_values => [:custom_attribute_id, :value, :choice_id]).tap do |whitelisted|
          whitelisted[:duration] = TimeParser.parse_time whitelisted[:duration]
        end
    end

end
