class WorkController < ApplicationController

  # Starts tracking time on the given task
  def start
    task = Task.accessed_by(current_user).find_by_task_num(params[:task_num])

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
        :duration => @current_sheet.duration,
        :customer_id => task.customers.first || @current_sheet.project.customer,
        :body => task.description,
        :paused_duration => @current_sheet.paused_duration,
        :log_type => EventLog::TASK_WORK_ADDED,
        :comment => @current_sheet.body.blank?
      }
      @current_sheet.destroy
      redirect_to new_work_log_path(:task_id => task.task_num, :work_log => link_params)
    else
      @current_sheet = nil
      flash['notice'] = _("Log entry already saved from another browser instance.")
      redirect_from_last
    end
  end

  def pause
    if @current_sheet
      if @current_sheet.paused?
        @current_sheet.paused_duration += (Time.now.utc - @current_sheet.paused_at).to_i
        @current_sheet.paused_at = nil
      else
        @current_sheet.paused_at = Time.now.utc
      end
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

end
