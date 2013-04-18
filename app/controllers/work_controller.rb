# encoding: UTF-8
class WorkController < ApplicationController
  before_filter :access_to_work

  # Starts tracking time on the given task
  def start
    task = TaskRecord.accessed_by(current_user).find_by_task_num(params[:task_num])

    if task
      sheet = Sheet.create(:task => task, :user => current_user,
                           :project => task.project)
      task.save

      @current_sheet = sheet
    end

    respond_to do |format|
      format.html { redirect_from_last }
    end
  end

  # stops work on the current task and prompts the user to save
  # their work in a log
  def stop
    if @current_sheet and @current_sheet.task
      task = @current_sheet.task

      link_params = {
        :duration => @current_sheet.duration / 60,
        :customer_id => task.customers.first || @current_sheet.project.customer,
        :body => task.description
      }
      @current_sheet.destroy
      redirect_to new_work_log_path(:task_id => task.task_num, :work_log => link_params)
    else
      @current_sheet = nil
      flash[:alert] = t('error.sheet.already_saved')
      redirect_from_last
    end
  end

  def pause
    if @current_sheet
      @current_sheet.start_pause
      @current_sheet.save
    end

    respond_to do |format|
      format.html { redirect_from_last }
    end
  end

  def cancel
    if @current_sheet
      @task = @current_sheet.task
      @current_sheet.destroy
      @current_sheet = nil
    end

    respond_to do |format|
      format.html { redirect_from_last }
    end
  end

  # GET /work/refresh.json
  def refresh
    percent = 0
    unless @current_sheet.task.duration.nil? or @current_sheet.task.duration == 0
      percent = ((@current_sheet.task.worked_minutes + @current_sheet.duration / 60) / @current_sheet.task.duration.to_f  * 100).round
    end
    render :json => {
      :duration => TimeParser.format_duration(@current_sheet.duration/60),
      :total => TimeParser.format_duration(@current_sheet.task.worked_minutes + @current_sheet.duration / 60),
      :percent => percent
    }
  end

  private
  def access_to_work
    unless current_user.option_tracktime.to_i == 1
      flash[:error] = _"You don't have access to track time"
      flash[:error] = t('flash.alert.access_denied_to_model', model: t('users.track_time'))
      redirect_from_last
      return false
    end
  end

end
