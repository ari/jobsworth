if RUBY_VERSION < "1.9" 
  require "fastercsv" 
else
  require "csv"
end

# Save a set of filters for access later on, with some predefined Views
#
class ViewsController < ApplicationController
  layout :decide_layout

  DEFAULTS = {
    :view => nil,
    :filter_user => [],
    :filter_customer => [],
    :filter_project => [],
    :filter_milestone => [],
    :filter_status => [ 0 ],
    :hide_deferred => 0,
    :hide_dependencies => 0,
    :show_all_unread => 0,
    :colors => 0,
    :icons => 0,
    :group_by => "",
    :sort => ""
  }

  def new
    @view = View.new
    @tags = Tag.top_counts(current_user.company)
  end

  def save_filter
    filter = TaskFilter.new(params[:task_filter])
    filter.save

    if filter.save
      flash['notice'] = _("Filter '%s' was successfully updated.", filter.name)
      redirect_to :action => 'select', :id => filter.id
    else
      flash["notice"] = _("Error saving filter")
      redirect_to(:back)
    end
  end

  def destroy
    if current_user.admin?
      @view = View.find(params[:id], :conditions => ["company_id = ?", current_user.company_id])
    else 
      @view = View.find(params[:id], :conditions => ["company_id = ? AND user_id = ?", current_user.company_id, current_user.id])
    end 
    flash['notice'] = _("View '%s' was deleted.", @view.name)
    @view.destroy
    redirect_from_last
  end

  def select
    filter = TaskFilter.find(params[:id], :conditions => ["company_id = ? AND (user_id = ? OR shared = 1)", current_user.company_id, current_user.id])
    session[:task_filter] = filter
    redirect_to :controller => "tasks", :action => "list"
  end

  def select_milestone
    begin
      @milestone = Milestone.find(params[:id], :conditions => ["company_id = ?", current_user.company_id])
    rescue
      flash['notice'] = _('Either the milestone doesn\'t exist, or you don\'t have access to it.')
      redirect_from_last
      return
    end

    set_session_filters(:filter_milestone => @milestone.id,
                        :last_project_id => session[:filter_project])

    redirect_to :controller => 'tasks', :action => 'list'
  end

  def select_project
    begin
    @project = Project.find(params[:id], :conditions => ["company_id = ? AND id IN (#{current_project_ids})", current_user.company_id])
    rescue 
      flash['notice'] = _('Either the project doesn\'t exist, or you don\'t have access to it.')
      redirect_from_last
      return
    end

    set_session_filters(:filter_project => @project.id, 
                        :last_project_id => session[:filter_project])

    redirect_to :controller => 'tasks', :action => 'list'
  end

  def select_user
    @user = User.find(params[:id], :conditions => ["company_id = ?", current_user.company_id])

    set_session_filters(:filter_user => @user.id)

    redirect_to :controller => 'tasks', :action => 'list'
  end

  def select_client
    @client = Customer.find(params[:id], :conditions => ["company_id = ?", current_user.company_id])
    
    set_session_filters(:filter_customer => @client.id)

    redirect_to :controller => 'tasks', :action => 'list'
  end

  def all_tasks
    @view = View.new
    @view.name = _('Open Tasks')

    set_session_filters(:view => @view)

    redirect_to :controller => 'tasks', :action => 'list'
  end

  def my_tasks
    @view = View.new
    @view.name = _('My Open Tasks')
    
    set_session_filters(:view => @view, :filter_user => current_user.id,
                        :filter_status => 0)

    redirect_to :controller => 'tasks', :action => 'list'
  end

  def my_in_progress_tasks
    @view = View.new
    @view.name = _('My In Progress Tasks')

    set_session_filters(:filter_user => current_user.id,
                        :filter_status => 1)

    redirect_to :controller => 'tasks', :action => 'list'
  end

  def unassigned_tasks
    @view = View.new
    @view.name = _('Unassigned Tasks')

    set_session_filters(:view => @view, :filter_user => -1)

    redirect_to :controller => 'tasks', :action => 'list'
  end

  def browse
    set_session_filters(:filter_status => [ 0, 1 ], 
                        :show_all_unread => 1, 
                        :filter_user => current_user.id,
                        :hide_deferred => 1)

    redirect_to(:controller => 'tasks', :action => 'list')
  end

  def get_projects
    if params[:customer_id].to_i == 0
      @projects = current_user.projects.collect {|p| "{\"text\":\"#{p.name} / #{p.customer.name}\", \"value\":#{p.id}}" }.join(',')
    else
      @projects = current_user.projects.find(:all, :conditions => ['customer_id = ? AND completed_at IS NULL', params[:customer_id]]).collect {|p| "{\"text\":\"#{p.name}\", \"value\":\"#{p.id.to_s}\"}" }.join(',')
    end

    res = '{"options":[{"value":0, "text":"' + _('[Any Project]') + '"}'
    res << ", #{@projects}" unless @projects.nil? || @projects.empty?
    res << ']}'
    render :text => res
  end

  def get_milestones
    if params[:project_id].to_i == 0
      @milestones = Milestone.find(:all, :order => "project_id, due_at", :conditions => ["project_id IN (#{current_project_ids}) AND completed_at IS NULL"]).collect  {|m| "{\"text\":\"#{m.name} / #{m.project.name}\", \"value\":#{m.id}}" }.join(',')

    else
      @milestones = Milestone.find(:all, :order => 'due_at, name', :conditions => ['company_id = ? AND project_id = ? AND completed_at IS NULL', current_user.company_id, params[:project_id]]).collect{|m| "{\"text\":\"#{m.name}\", \"value\":#{m.id}}" }.join(',')
    end

    res = '{"options":[{"value":0, "text":"' + _('[Any Milestone]') + '"}'
    res << ", #{@milestones}" unless @milestones.nil? || @milestones.empty?
    res << ']}'
    render :text => res
  end

  def get_owners
    if params[:project_id].to_i == 0
      @users = User.find(:all, :order => "name", :conditions => ["company_id = ?", current_user.company_id]).collect {|u| "{\"text\":\"#{u.name.gsub(/"/,'\"')}\", \"value\":\"#{u.id.to_s}\"}" }.join(',')
    else
      @users = Project.find(:first, :conditions => ['company_id = ? AND id = ?', current_user.company_id, params[:project_id]]).users.collect  {|u| "{\"text\":\"#{u.name.gsub(/"/,'\"')}\", \"value\":\"#{u.id.to_s}\"}" }.join(',')
    end

    res = '{"options":[{"value":"0", "text":"' + _('[Any User]') + '"},{"value":"-2","text":"' + _('[Active User]') + '"},{"value":"-1","text":"' + _('[Unassigned]') + '"}'

    res << ", #{@users}" unless @users.nil? || @users.empty?
    res << ']}'
    render :text => res
  end

  private

  ###
  # Removes any property filters from the current
  # session.
  ###
  def reset_property_filters
    current_user.company.properties.each do |p|
      session[p.filter_name] = nil
    end
  end

  ###
  # Sets the session to use the given filters. Any values
  # not passed are set to their defaults.
  ###
  def set_session_filters(filters)
    reset_property_filters
    filters = DEFAULTS.merge(filters)

    filters.each do |filter, value|
      session[filter] = value
    end
  end

end
