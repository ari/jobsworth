# Show recent activities, and handle the simple tutorial
#
# Author:: Erlend Simonsen (mailto:admin@clockingit.com)
class ActivitiesController < ApplicationController

  # Redirect to list
  def index
    list
    render :action => 'list'
  end

  # Show the overview page including
  # * Top Priority Task
  # * Recent Task
  # * Latest WorkLog
  # * Project
  # * Milestone progress
  # * Progress
  def list

    session[:channels] += ["activity_#{current_user.company_id}"]

#    @projects = current_user.projects.find(:all, :order => 't1_r2, projects.name', :conditions => ["projects.completed_at IS NULL"], :include => [ :customer, :milestones]);
#    @completed_projects = current_user.completed_projects.find(:all).size
#    @activities = EventLog.find(:all, :order => "event_logs.created_at DESC", :limit => 25, :conditions => ["company_id = ? AND (event_logs.project_id IN ( #{current_project_ids} ) OR event_logs.project_id IS NULL)", current_user.company_id] )

#    @tasks = Task.find(:all, :conditions => ["tasks.project_id IN (#{current_project_ids}) AND tasks.completed_at IS NULL AND tasks.company_id = #{current_user.company_id} AND (tasks.hide_until IS NULL OR tasks.hide_until < '#{tz.now.utc.to_s(:db)}') AND (tasks.milestone_id NOT IN (#{completed_milestone_ids}) OR tasks.milestone_id IS NULL)"],  :order => "tasks.severity_id + tasks.priority desc, CASE WHEN (tasks.due_at IS NULL AND milestones.due_at IS NULL) THEN 1 ELSE 0 END, CASE WHEN (tasks.due_at IS NULL AND tasks.milestone_id IS NOT NULL) THEN milestones.due_at ELSE tasks.due_at END", :include => [:tags, :work_logs, :milestone, { :project => :customer }, :dependencies, :dependants, :users, :todos ], :limit => 5  )

#    new_filter = ""
#    new_filter = "AND tasks.id NOT IN (" + @tasks.collect{ |t| t.id}.join(', ') + ")" if @tasks.size > 0

#    @new_tasks = Task.find(:all, :conditions => ["tasks.project_id IN (#{current_project_ids}) #{new_filter} AND tasks.company_id = #{current_user.company_id} AND tasks.completed_at IS NULL AND (tasks.hide_until IS NULL OR tasks.hide_until < '#{tz.now.utc.to_s(:db)}') AND (tasks.milestone_id NOT IN (#{completed_milestone_ids}) OR tasks.milestone_id IS NULL)"],  :order => "tasks.created_at desc", :include => [:tags, :work_logs, :milestone, { :project => :customer }, :dependencies, :dependants, :users, :work_logs, :todos], :limit => 5  )
  end

  # Update the page, due to a Juggernaut push message
  def refresh
#    @projects = current_user.projects.find(:all, :order => 't1_r2, projects.name', :conditions => ["projects.completed_at IS NULL"], :include => [ :customer, :milestones]);
#    @completed_projects = current_user.completed_projects.find(:all).size
#    @activities = EventLog.find(:all, :order => "event_logs.created_at DESC", :limit => 25, :conditions => ["company_id = ? AND (event_logs.project_id IN ( #{current_project_ids} ) OR event_logs.project_id IS NULL)", current_user.company_id] )

#    @tasks = current_user.tasks.find(:all, :conditions => [" tasks.company_id = #{current_user.company_id} AND tasks.project_id IN (#{current_project_ids}) AND tasks.completed_at IS NULL AND (tasks.hide_until IS NULL OR tasks.hide_until < '#{tz.now.utc.to_s(:db)}') AND (tasks.milestone_id NOT IN (#{completed_milestone_ids}) OR tasks.milestone_id IS NULL)"],  :order => "tasks.severity_id + tasks.priority desc, CASE WHEN (tasks.due_at IS NULL AND milestones.due_at IS NULL) THEN 1 ELSE 0 END, CASE WHEN (tasks.due_at IS NULL AND tasks.milestone_id IS NOT NULL) THEN milestones.due_at ELSE tasks.due_at END LIMIT 5", :include => [:milestone]  )

#    new_filter = ""
#    new_filter = "AND tasks.id NOT IN (" + @tasks.collect{ |t| t.id}.join(', ') + ")" if @tasks.size > 0

#    @new_tasks = Task.find(:all, :conditions => ["tasks.company_id = #{current_user.company_id} AND tasks.project_id IN (#{current_project_ids}) #{new_filter} AND tasks.completed_at IS NULL AND (tasks.hide_until IS NULL OR tasks.hide_until < '#{tz.now.utc.to_s(:db)}') AND (tasks.milestone_id NOT IN (#{completed_milestone_ids}) OR tasks.milestone_id IS NULL)"],  :order => "tasks.created_at desc", :include => [:milestone], :limit => 5  )
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
