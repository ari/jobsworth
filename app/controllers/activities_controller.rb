# Show recent activities, and handle the simple tutorial
#
# Author:: Erlend Simonsen (mailto:admin@clockingit.com)
class ActivitiesController < ApplicationController

  # Redirect to list
  def index
    list
    render_action 'list'
  end

  # Show the overview page including
  # * Top Priority Task
  # * Recent Task
  # * Latest WorkLog
  # * Project
  # * Milestone progress
  # * Progress
  def list

    session[:channels] += ["activity_#{session[:user].company_id}"]

    @projects = User.find(session[:user].id).projects.find(:all, :order => 't1_r2, projects.name', :conditions => ["projects.completed_at IS NULL"], :include => [ :customer, :milestones]);
    @completed_projects = User.find(session[:user].id).projects.find(:all, :conditions => ["projects.completed_at IS NOT NULL"]).size
    @activities = WorkLog.find(:all, :order => "work_logs.started_at DESC", :limit => 25, :conditions => ["work_logs.project_id IN ( #{current_project_ids} )"], :include => [:user, :project, :customer, :task])

    user = User.find(session[:user].id)

    @tasks = user.tasks.find(:all, :conditions => ["tasks.company_id = #{session[:user].company_id} AND tasks.project_id IN (#{current_project_ids}) AND tasks.completed_at IS NULL AND tasks.milestone_id NOT IN (#{completed_milestone_ids})"],  :order => "tasks.severity_id + tasks.priority desc, CASE WHEN (tasks.due_at IS NULL AND milestones.due_at IS NULL) THEN 1 ELSE 0 END, CASE WHEN (tasks.due_at IS NULL AND tasks.milestone_id IS NOT NULL) THEN milestones.due_at ELSE tasks.due_at END LIMIT 5", :include => [:milestone]  )

    new_filter = ""
    new_filter = "AND tasks.id NOT IN (" + @tasks.collect{ |t| t.id}.join(', ') + ")" if @tasks.size > 0

    @new_tasks = Task.find(:all, :conditions => ["tasks.company_id = #{session[:user].company_id} AND tasks.project_id IN (#{current_project_ids}) #{new_filter} AND tasks.completed_at IS NULL AND tasks.milestone_id NOT IN (#{completed_milestone_ids})"],  :order => "tasks.created_at desc", :include => [:milestone], :limit => 5  )

  end

  # Update the page, due to a Juggernaut push message
  def refresh
    user = User.find(session[:user].id)
    @projects = User.find(session[:user].id).projects.find(:all, :order => 't1_r2, projects.name', :conditions => ["projects.completed_at IS NULL"], :include => [ :customer, :milestones]);
    @completed_projects = User.find(session[:user].id).projects.find(:all, :conditions => ["projects.completed_at IS NOT NULL"]).size
    @activities = WorkLog.find(:all, :order => "work_logs.started_at DESC", :limit => 25, :conditions => ["work_logs.project_id IN ( #{current_project_ids} )"], :include => [:user, :project, :customer, :task])

    @tasks = user.tasks.find(:all, :conditions => [" tasks.company_id = #{session[:user].company_id} AND tasks.project_id IN (#{current_project_ids}) AND tasks.completed_at IS NULL AND tasks.milestone_id NOT IN (#{completed_milestone_ids})"],  :order => "tasks.severity_id + tasks.priority desc, CASE WHEN (tasks.due_at IS NULL AND milestones.due_at IS NULL) THEN 1 ELSE 0 END, CASE WHEN (tasks.due_at IS NULL AND tasks.milestone_id IS NOT NULL) THEN milestones.due_at ELSE tasks.due_at END LIMIT 5", :include => [:milestone]  )

    new_filter = ""
    new_filter = "AND tasks.id NOT IN (" + @tasks.collect{ |t| t.id}.join(', ') + ")" if @tasks.size > 0

    @new_tasks = Task.find(:all, :conditions => ["tasks.company_id = #{session[:user].company_id} AND tasks.project_id IN (#{current_project_ids}) #{new_filter} AND tasks.completed_at IS NULL AND tasks.milestone_id NOT IN (#{completed_milestone_ids})"],  :order => "tasks.created_at desc", :include => [:milestone], :limit => 5  )
  end

  # Simple tutorial, guiding the user through
  # * Creating a Project
  # * Creating a Task
  # * Adding a WorkLog
  # * Completing a Task
  # * Adding a User
  def welcome
    @projects_count = current_projects.size
    @tasks_count = Task.count(:conditions => ["company_id = ? AND project_id IN (#{current_project_ids})", session[:user].company_id ])
    @work_count = WorkLog.count(:conditions => ["company_id = ? AND project_id IN (#{current_project_ids} ) AND log_type = #{WorkLog::TASK_WORK_ADDED}", session[:user].company_id])
    @completed_count = Task.count(:conditions => ["company_id = ? AND project_id IN (#{current_project_ids}) AND completed_at IS NOT NULL", session[:user].company_id ])
    @users_count = User.count(:conditions => ["company_id = ?", session[:user].company_id])

    if @projects_count > 0 && @tasks_count > 0 && @work_count > 0 && @completed_count > 0 && @users_count > 1
      u = User.find(session[:user].id)
      u.seen_welcome = 1
      u.save
      flash['notice'] = _('Tutorial completed. It will no longer be shown in the menu.')
    end

  end

  # Skip the tutorial
  def hide_welcome
    u = User.find(session[:user].id)
    u.seen_welcome = 1
    u.save
    flash['notice'] = _('Tutorial hidden. It will no longer be shown in the menu.')
    redirect_to :controller => 'activities', :action => 'list'
  end

end
