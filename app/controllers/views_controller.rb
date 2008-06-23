# Save a set of filters for access later on, with some predefined Views
#
class ViewsController < ApplicationController

  def new
    @view = View.new
    @view.filter_status = -1
    @view.filter_type_id = -1
    @tags = Tag.top_counts({ :company_id => current_user.company_id, :project_ids => current_project_ids })
  end

  def create
    @view = View.new(params[:view])
    @view.company_id = current_user.company_id
    @view.user_id = current_user.id
    if @view.save
      flash['notice'] = _("View '%s' was successfully created.", @view.name)
      redirect_to :action => 'select', :id => @view.id
    else
      render :action => 'new'
    end
  end

  def edit
    @view = View.find(params[:id], :conditions => ["company_id = ? AND user_id = ?", current_user.company_id, current_user.id])
    @tags = Tag.top_counts({ :company_id => current_user.company_id, :project_ids => current_project_ids })
  end

  def update
    @view = View.find(params[:id], :conditions => ["company_id = ? AND user_id = ?", current_user.company_id, current_user.id])
    @view.attributes = params[:view]
    @view.shared = 0 if params[:view][:shared].nil?
    @view.auto_group = 0 unless params[:view][:auto_group]
    @view.filter_tags = @view.filter_tags.split(',').collect{ |t|
      unless t.length == 0
        t.strip.downcase
      else
        nil
      end
      }.compact.join(',')
    if @view.save

      flash['notice'] = _("View '%s' was successfully updated.", @view.name)
      redirect_to :action => 'select', :id => @view.id
    else
      render :action => 'edit'
    end
  end

  def save_filter
    @view = View.new
    @view.filter_user_id = session[:filter_user].to_i
    @view.filter_project_id = session[:filter_project].to_i
    @view.filter_milestone_id = session[:filter_milestone].to_i
    @view.auto_group = session[:group_by].to_i
    @view.hide_dependencies = session[:hide_dependencies].to_i
    @view.filter_status = session[:filter_status].to_i
    @view.sort = session[:sort].to_i

    @view.filter_tags = params[:tags].split(',').collect{ |t|
      unless t.length == 0
        t.strip.downcase
      else
        nil
      end
      }.compact.join(',') if params[:tags]

    @tags = Tag.top_counts({ :company_id => current_user.company_id, :project_ids => current_project_ids })
    render :action => 'new'
  end

  def destroy
    @view = View.find(params[:id], :conditions => ["company_id = ? AND user_id = ?", current_user.company_id, current_user.id])
    flash['notice'] = _("View '%s' was deleted.", @view.name)
    @view.destroy
    redirect_from_last
  end

  def select
    @view = View.find(params[:id], :conditions => ["company_id = ? AND (user_id = ? OR shared = 1)", current_user.company_id, current_user.id])

    session[:filter_user] = @view.filter_user_id.to_s if (@view.filter_user_id >= 0 || @view.filter_user_id == -1)
    session[:filter_user] = current_user.id.to_s if @view.filter_user_id == -2
    session[:filter_project] = @view.filter_project_id.to_s
    session[:filter_milestone] = @view.filter_milestone_id.to_s
    session[:group_by] = @view.auto_group.to_s
    session[:hide_dependencies] = @view.hide_dependencies.to_s
    session[:filter_hidden] = "0"
    session[:filter_status] = @view.filter_status
    session[:filter_type] = @view.filter_type_id.to_s
    session[:filter_customer] = @view.filter_customer_id.to_s
    session[:sort] = @view.sort.to_s

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
    @milestone = Milestone.find(params[:id], :conditions => ["company_id = ?", current_user.company_id])
    session[:filter_user] = "0"
    session[:filter_project] = @milestone.project.id.to_s
    session[:filter_milestone] = @milestone.id.to_s
    session[:hide_dependencies] = "0"
    session[:filter_hidden] = "0"
    session[:filter_status] = "0"
    session[:filter_type] = "-1"
    session[:filter_customer] = "0"
    session[:view] = nil
    redirect_to :controller => 'tasks', :action => 'list'
  end

  def select_project
    @project = Project.find(params[:id], :conditions => ["company_id = ? AND id IN (#{current_project_ids})", current_user.company_id])
    session[:filter_user] = "0"
    session[:filter_project] = @project.id.to_s
    session[:filter_milestone] = "0"
    session[:hide_dependencies] = "0"
    session[:filter_hidden] = "0"
    session[:filter_status] = "0"
    session[:filter_type] = "-1"
    session[:filter_customer] = "0"
    session[:view] = nil
    redirect_to :controller => 'tasks', :action => 'list'
  end

  def select_user
    @user = User.find(params[:id], :conditions => ["company_id = ?", current_user.company_id])
    session[:filter_user] = @user.id.to_s
    session[:filter_project] = "0"
    session[:filter_milestone] = "0"
    session[:hide_dependencies] = "0"
    session[:filter_hidden] = "0"
    session[:filter_status] = "0"
    session[:filter_type] = "-1"
    session[:filter_customer] = "0"
    session[:view] = nil
    redirect_to :controller => 'tasks', :action => 'list'
  end

  def select_client
    @client = Customer.find(params[:id], :conditions => ["company_id = ?", current_user.company_id])
    session[:filter_user] = "0"
    session[:filter_project] = "0"
    session[:filter_milestone] = "0"
    session[:hide_dependencies] = "0"
    session[:filter_hidden] = "0"
    session[:filter_status] = "0"
    session[:filter_type] = "-1"
    session[:filter_customer] = @client.id
    session[:view] = nil
    redirect_to :controller => 'tasks', :action => 'list'
  end

  def all_tasks

    @view = View.new
    @view.name = _('Open Tasks')

    session[:view] = @view

    session[:filter_user] = "0"
    session[:filter_project] = "0"
    session[:filter_milestone] = "0"
    session[:filter_status] = "0"
    session[:filter_hidden] = "0"
    session[:hide_dependencies] = "0"
    session[:filter_type] = "-1"
    session[:filter_customer] = "0"
    redirect_to :controller => 'tasks', :action => 'list'
  end

  def my_tasks
    @view = View.new
    @view.name = _('My Open Tasks')

    session[:view] = @view
    session[:filter_user] = current_user.id.to_s
    session[:filter_project] = "0"
    session[:filter_milestone] = "0"
    session[:filter_status] = "0"
    session[:filter_hidden] = "0"
    session[:filter_type] = "-1"
    session[:hide_dependencies] = "1"
    session[:filter_customer] = "0"
    redirect_to :controller => 'tasks', :action => 'list'
  end

  def my_in_progress_tasks
    @view = View.new
    @view.name = _('My In Progress Tasks')

    session[:view] = @view
    session[:filter_user] = current_user.id.to_s
    session[:filter_project] = "0"
    session[:filter_milestone] = "0"
    session[:filter_status] = "1"
    session[:filter_hidden] = "0"
    session[:filter_type] = "-1"
    session[:hide_dependencies] = "1"
    session[:filter_customer] = "0"
    redirect_to :controller => 'tasks', :action => 'list'
  end

  def unassigned_tasks
    @view = View.new
    @view.name = _('Unassigned Tasks')

    session[:view] = @view
    session[:filter_user] = "-1"
    session[:filter_project] = "0"
    session[:filter_milestone] = "0"
    session[:filter_status] = "0"
    session[:filter_hidden] = "0"
    session[:filter_type] = "-1"
    session[:hide_dependencies] = "0"
    session[:filter_customer] = "0"
    redirect_to :controller => 'tasks', :action => 'list'
  end

  def browse
    session[:view] = nil
    session[:filter_status] = "0"
    session[:filter_hidden] = "0"
    session[:filter_type] = "-1"
    session[:hide_dependencies] = "1"
    redirect_to :controller => 'tasks', :action => 'list'
  end

  def get_projects
    if params[:customer_id].to_i == 0
      @projects = current_user.projects.collect {|p| "{\"text\":\"#{p.name} / #{p.customer.name}\", \"value\":\"#{p.id.to_s}\"}" }.join(',')
    else
      @projects = current_user.projects.find(:all, :conditions => ['customer_id = ? AND completed_at IS NULL', params[:customer_id]]).collect {|p| "{\"text\":\"#{p.name}\", \"value\":\"#{p.id.to_s}\"}" }.join(',')
    end

    res = '{"options":[{"value":"0", "text":"' + _('[Any Project]') + '"}'
    res << ", #{@projects}" unless @projects.nil? || @projects.empty?
    res << ']}'
    render :text => res
  end

  def get_milestones
    if params[:project_id].to_i == 0
      @milestones = Milestone.find(:all, :order => "project_id, due_at", :conditions => ["company_id = ? AND completed_at IS NULL", current_user.company_id]).collect  {|m| "{\"text\":\"#{m.name} / #{m.project.name}\", \"value\":\"#{m.id.to_s}\"}" }.join(',')

    else
      @milestones = Milestone.find(:all, :order => 'due_at, name', :conditions => ['company_id = ? AND project_id = ? AND completed_at IS NULL', current_user.company_id, params[:project_id]]).collect{|m| "{\"text\":\"#{m.name}\", \"value\":\"#{m.id.to_s}\"}" }.join(',')
    end

    res = '{"options":[{"value":"0", "text":"' + _('[Any Milestone]') + '"}'
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

end
