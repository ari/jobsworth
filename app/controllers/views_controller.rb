require "fastercsv"

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
    @tags = Tag.top_counts({ :company_id => current_user.company_id, :project_ids => current_project_ids })
  end

  def save_filter
    @view = View.new(params[:view])
    tf = TaskFilter.new(self, session)

    @view.company_id = current_user.company_id
    @view.user_id = current_user.id

    user_ids = TaskFilter.filter_user_ids(session).to_csv
    @view.filter_user_id = user_ids if !user_ids.blank?

    project_ids = tf.project_ids.to_csv
    @view.filter_project_id = project_ids if !project_ids.blank?

    milestone_ids = tf.milestone_ids.to_csv
    @view.filter_milestone_id = milestone_ids if !milestone_ids.blank?

    customer_ids = tf.customer_ids.to_csv
    @view.filter_customer_id = customer_ids if !customer_ids.blank?

    status_ids = TaskFilter.filter_status_ids(session).to_csv
    @view.filter_status = status_ids if !status_ids.blank?

    @view.auto_group = session[:group_by].to_i
    @view.hide_deferred = session[:hide_deferred].to_i
    @view.hide_dependencies = session[:hide_dependencies].to_i

    @view.sort = session[:sort].to_i
    @view.colors = session[:colors].to_i
    @view.icons = session[:icons].to_i

    @view.property_values.clear
    current_user.company.properties.each do |prop|
      value_ids = session[prop.filter_name]
      next if !value_ids

      value_ids.each do |id|
        value = prop.property_values.detect { |pv| pv.id == id.to_i }
        @view.property_values << value if value
      end
    end

    @view.filter_tags = params[:tags].split(',').collect{ |t|
      unless t.length == 0
        t.strip.downcase
      else
        nil
      end
      }.compact.join(',') if params[:tags]

    if @view.save
      flash['notice'] = _("View '%s' was successfully updated.", @view.name)
      redirect_to :action => 'select', :id => @view.id
    else
      flash["notice"] = _("Error saving view")
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
    @view = View.find(params[:id], :conditions => ["company_id = ? AND (user_id = ? OR shared = 1)", current_user.company_id, current_user.id])

    session[:filter_user] = (@view.filter_user_id || "").parse_csv
    session[:filter_project] = (@view.filter_project_id || "").parse_csv
    session[:filter_status] = (@view.filter_status || "").parse_csv
    session[:filter_milestone] = (@view.filter_milestone_id || "").parse_csv
    session[:filter_customer] = (@view.filter_customer_id || "").parse_csv

    session[:last_project_id] = session[:filter_project]

    session[:group_by] = @view.auto_group.to_s
    session[:hide_deferred] = @view.hide_deferred.to_s
    session[:hide_dependencies] = @view.hide_dependencies.to_s
    session[:filter_hidden] = "0"

    session[:filter_type] = @view.filter_type_id.to_s
    session[:filter_severity] = @view.filter_severity.to_s
    session[:filter_priority] = @view.filter_priority.to_s

    session[:sort] = @view.sort.to_s
    session[:colors] = @view.colors.to_s
    session[:icons] = @view.icons.to_s

    reset_property_filters
    # set filters for property values
    @view.property_values.each do |pv|
      filter_name = pv.property.filter_name
      values = session[filter_name] || []
      values << pv.id
      session[filter_name] = values
    end

    @view.filter_tags = @view.filter_tags.split(',').collect{ |t|
      unless t.length == 0
        t.strip.downcase
      else
        nil
      end
      }.compact.join(',')

    session[:view] = @view

    redirect_to :controller => 'tasks', :action => 'list', :tag => @view.filter_tags
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
