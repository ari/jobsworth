# Show recent activities, and handle the simple tutorial
#
# Author:: Erlend Simonsen (mailto:admin@clockingit.com)
class ActivitiesController < ApplicationController

  # Redirect to list
  def index
    list
    render :action => 'list'
  end

  # Show the overview page including whatever widgets the user has added.
  def list
    session[:channels] += ["activity_#{current_user.company_id}", "tasks_#{current_user.company_id}"]
  end

  # Update the page, due to a Juggernaut push message
  def refresh
  end

  # Simple tutorial, guiding the user through
  # * Creating a Project
  # * Creating a Task
  # * Adding a WorkLog
  # * Completing a Task
  # * Adding a User
  def welcome
    @projects_count  = current_projects.size
    @tasks_count     = Task.count(:conditions => ["company_id = ? AND project_id IN (#{current_project_ids})", current_user.company_id ])
    @work_count      = WorkLog.count(:conditions => ["company_id = ? AND project_id IN (#{current_project_ids} ) AND log_type = #{EventLog::TASK_WORK_ADDED}", current_user.company_id])
    @completed_count = Task.count(:conditions => ["company_id = ? AND project_id IN (#{current_project_ids}) AND completed_at IS NOT NULL", current_user.company_id ])
    @users_count     = User.count(:conditions => ["company_id = ?", current_user.company_id])

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

  def toggle_display
    session[:collapse_projects] ||= {}
    session[:collapse_projects][params[:id]] = 1 - session[:collapse_projects][params[:id]].to_i
  end

  def toggle_display_milestones
    session[:collapse_milestones] ||= {}
    session[:collapse_milestones][params[:id]] = 1 - session[:collapse_milestones][params[:id]].to_i
  end

  def toggle_menu
    session[:collapse_menu] ||= 0
    session[:collapse_menu] = 1 - session[:collapse_menu].to_i
    render :update do |page|
      page.toggle('left_menu')
    end
  end

end
