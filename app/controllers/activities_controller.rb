# encoding: UTF-8
# Show recent activities, and handle the simple tutorial
#
class ActivitiesController < ApplicationController
  # Redirect to list
  def index
    list
    render :action => 'list'
  end

  # Show the overview page including whatever widgets the user has added.
  def list
   session[:user_id]=session["warden.user.user.key"][1]
  end

  # Simple tutorial, guiding the user through
  # * Creating a Project
  # * Creating a Task
  # * Adding a WorkLog
  # * Completing a Task
  # * Adding a User
  def welcome
    @projects_count  = current_projects.size
    @tasks_count     = Task.where("company_id = ? AND project_id IN (?)", current_user.company_id, current_project_ids).count
    @work_count      = WorkLog.accessed_by(current_user).where(:log_type=>EventLog::TASK_WORK_ADDED).count
    @completed_count = Task.where("company_id = ? AND project_id IN (?) AND completed_at IS NOT NULL", current_user.company_id, current_project_ids).count
    @users_count     = User.where("company_id = ?", current_user.company_id).count

    if @projects_count > 0 && @tasks_count > 0 && @work_count > 0 && @completed_count > 0 && @users_count > 1
      u = current_user
      u.seen_welcome = 1
      u.save
      flash['notice'] = _('Tutorial completed. It will no longer be shown in the menu.')
    end

  end

  # Skip the tutorial
  def hide_welcome
    u = current_user
    u.seen_welcome = 1
    u.save
    flash['notice'] = _('Tutorial hidden. It will no longer be shown in the menu.')
    redirect_to :controller => 'activities', :action => 'list'
  end
end
