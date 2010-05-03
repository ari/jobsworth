class WorkLogsController < ApplicationController
  before_filter :load_log, :only => [ :edit, :update, :destroy ]
  before_filter :load_task_and_build_log, :only => [ :new, :create ]

  helper_method :can_delete_log?

  def new
  end

  def create
    setup_log_from_params

    if @log.save
      update_task_for_log(@log, params[:task])

      flash['notice'] = _("Log entry created...")
      redirect_from_last
    else
      flash["notice"] = _("Error creating log entry")
      render :new
    end
  end

  def edit
  end

  def update
    setup_log_from_params

    if @log.save
      update_task_for_log(@log, params[:task])

      flash['notice'] = _("Log entry saved...")
      redirect_from_last
    else
      flash["notice"] = _("Error saving log entry")
      render :edit
    end
  end

  def destroy
    if can_delete_log?(@log)
      @log.destroy
      flash[:notice] = _("Log entry deleted...")
    else
      flash[:notice] = _("You don't have access to that log...")
    end

    redirect_from_last
  end

  private

  # Loads the log using the given params
  def load_log
    @log = WorkLog.all_accessed_by(current_user).find(params[:id])
    @task = @log.task
  end

  # Loads the task new logs should be linked to
  def load_task_and_build_log
    @task = current_user.company.tasks.find_by_task_num(params[:task_id])
    @log = current_user.company.work_logs.build(params[:work_log])
    @log.task = @task
    @log.started_at = tz.utc_to_local(Time.now.utc)
  end

  # Returns true if the current user can delete the given log
  def can_delete_log?(log)
    return (!log.new_record? and
            (current_user.admin? || log.user == current_user))
  end

  # Some params need to be parsed before saving, so do that here
  def setup_log_from_params
    params[:work_log][:started_at] = date_from_params(params[:work_log], :started_at)
    params[:work_log][:duration] = parse_time(params[:work_log][:duration])
    params[:work_log][:comment] = !params[:work_log][:body].blank?

    @log.attributes = params[:work_log]
    @log.user = current_user
    @log.project = @task.project
  end

  ###
  # Updates the task linked to log.
  ###
  def update_task_for_log(log, task_params)
    return if task_params.nil?
    new_status = task_params[:status].to_i

    if new_status != log.task.status
      status_type = :completed

      if new_status < 2
        log.log_type = EventLog::TASK_WORK_ADDED
        status_type = :updated
      end

      if new_status > 1 && log.task.status < 2
        log.log_type = EventLog::TASK_COMPLETED
        status_type = :completed
      end

      if new_status < 2 && log.task.status > 1
        log.log_type = EventLog::TASK_REVERTED
        status_type= :reverted
      end

      log.task.status = new_status
      log.task.updated_by_id = current_user.id
      log.task.completed_at = Time.now.utc
    end

    log.task.save
  end


end
