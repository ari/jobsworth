# encoding: UTF-8
class UsersController < ApplicationController
  layout :decide_layout
  before_filter :protect_admin_area, :only=>[:index, :new, :create, :edit, :update, :destroy]

  def index
    @users = paginate User.where("users.company_id = ?", current_user.company_id)
                          .includes(:project_permissions => {:project => :customer})
                          .order("users.name")
  end

  def new
    @user = User.new(params[:user])
    @user.company_id = current_user.company_id
    @user.customer_id = current_user.customer_id if @user.customer_id.blank?
    @user.time_zone = current_user.time_zone
    @user.create_projects = 0
    @user.option_tracktime = 0
  end

  def create
    @user = User.new(params[:user])
    @user.company_id = current_user.company_id  

    # The order of the following two lines is important
    @user.emails = params[:emails] if params[:emails]
    @user.new_emails = params[:new_emails] if params[:new_emails]
    if @user.errors.size > 0
      flash[:error] = @user.errors.full_messages.join(". ")
      return render :action => 'new'
    end

    if params[:user][:admin].to_i <= current_user.admin
      @user.admin=params[:user][:admin]
    end

    if @user.save
      if params[:copy_user].to_i > 0
        u = current_user.company.users.find(params[:copy_user])
        u.project_permissions.each do |perm|
          p = perm.dup
          p.user = @user
          p.save
        end
      end

      flash[:success] = _('User was successfully created. Remember to give this user access to needed projects.')

      if params[:send_welcome_email]
        begin
          Signup::account_created(@user, current_user, params['welcome_message']).deliver
        rescue
          flash[:error] ||= ""
          flash[:error] += ("<br/>" + _("Error sending creation email. Account still created.")).html_safe
        end
      end

      redirect_to :action => 'edit', :id => @user
    else
      flash[:error] = @user.errors.full_messages.join(". ")
      render :action => 'new'
    end
  end

  def edit
    @user = User.where("company_id = ?", current_user.company_id).find(params[:id])
  end

  def update
    @user = User.where("company_id = ?", current_user.company_id).find(params[:id])

    if params[:user][:admin].to_i <= current_user.admin
      @user.admin = params[:user][:admin]
    end

    if current_user.admin?
      @user.set_access_control_attributes(params[:user])
    end

    # The order of the following two lines is important
    @user.emails = params[:emails] if params[:emails]
    @user.new_emails = params[:new_emails] if params[:new_emails]
    if @user.errors.size > 0
      flash[:error] = @user.errors.full_messages.join(". ")
      return render :action => 'edit'
    end

    if @user.update_attributes(params[:user])
      flash[:success] = _('User was successfully updated.')
      if @user.customer
        redirect_to(:controller => "customers", :action => 'edit',
                    :id => @user.customer, :anchor => "users")
      else
        redirect_to(:controller => "customers", :action => "index")
      end
    else
      flash[:error] = @user.errors.full_messages.join(". ")
      render :action => 'edit'
    end
  end

  def edit_preferences
    @user = current_user
  end

  def update_preferences
    @user = User.where("company_id = ?", current_user.company_id).find(params[:id])

    # The order of the following two lines is important
    @user.emails = params[:emails] if params[:emails]
    @user.new_emails = params[:new_emails] if params[:new_emails]
    if @user.errors.size > 0
      flash[:error] = @user.errors.full_messages.join(". ")
      return render :action => 'edit_preferences'
    end

    if (@user == current_user) and @user.update_attributes(params[:user])
      flash[:success] = _('Preferences successfully updated.')
      redirect_to :controller => 'activities', :action => 'index'
    else
      @user=current_user unless @user == current_user
      render :action => 'edit_preferences'
    end
  end

  def destroy
    if current_user.id == params[:id].to_i
      flash[:error] = _("You can't delete yourself.")
      redirect_to(:controller => "customers", :action => 'index')
      return
    end

    @user = User.where("company_id = ?", current_user.company_id).find(params[:id])
    flash[:error] = @user.errors.full_messages.join(' ') unless @user.destroy

    redirect_to(:controller => "customers", :action => 'edit', :id => @user.customer_id)
  end

  # Used while debugging
  def impersonate
    if current_user.admin > 9
      @user = User.find(params[:id])
      if @user != nil
        current_user = @user
        session[:project] = nil
        session[:sheet] = nil
      end
    end
    redirect_to(:controller => "customers", :action => 'index')
  end

  def update_seen_news
    if request.xhr?
      @user = current_user
      unless @user.nil?
        @user.seen_news_id = params[:id]
        @user.save
      end
    end
    render :nothing => true
  end

  def upload_avatar
    if params['user'].nil? || params['user']['tmp_file'].nil? || !params['user']['tmp_file'].respond_to?('original_filename')
      flash[:error] = _('No file selected.')
      redirect_from_last
      return
    end
    @user = User.where("company_id = ?", current_user.company_id).find(params[:id])

    if @user.avatar?
      @user.avatar.destroy rescue begin
        flash[:error] = _("Permission denied while deleting old avatar.")
        redirect_to :action => 'edit_preferences'
        return
      end
    end

    unless params['user']['tmp_file'].size > 0
      flash[:error] = _('Empty file uploaded.')
      redirect_to :action => 'edit_preferences'
      return
    end

    @user.avatar=params['user']['tmp_file']
    @user.save! rescue begin
      flash[:error] = _("Permission denied while saving file.")
      redirect_to :action => 'edit_preferences'
      return
    end
    flash[:success] = _('Avatar successfully uploaded.')
    redirect_from_last
  end

  def delete_avatar
    @user = User.where("company_id = ?", current_user.company_id).find(params[:id])
    unless @user.nil? && !@user.avatar?
      @user.avatar.destroy #rescue begin end
    end
    redirect_from_last
  end

  def avatar
    @user = User.find(params[:id])
    unless @user.avatar?
      render :nothing => true
      return
    end
    if params[:large]
      send_file @user.avatar_large_path, :filename => "avatar", :type => 'image/jpeg', :disposition => 'inline'
    else
      send_file @user.avatar_path, :filename => "avatar", :type => 'image/jpeg', :disposition => 'inline'
    end
  end

  def auto_complete_for_project_name
    text = params[:term]
    if !text.blank?
      @projects = current_user.company.projects.where("lower(name) like ?", "%#{ text }%")
    end
    render :json=> @projects.collect{|project| {:value => project.name, :id=> project.id} }.to_json

  end

  def project
    @user = current_user.company.users.active.find(params[:id])

    project = current_user.company.projects.find(params[:project_id])

    ProjectPermission.new(:user => @user, :company => @user.company,
                          :project => project).save

    render(:partial => "project", :locals => { :project => project, :user_edit => true })

  end

  def set_preference
    current_user.preference_attributes = [ [ params[:name], params[:value] ] ]
    render :nothing => true
  end

  def get_preference
    render :text => current_user.preference(params[:name])
  end

  def set_tasklistcols
    current_user.preference_attributes = [ [ 'tasklistcols', params[:model] ] ]
    Rails.cache.delete("get_tasklistcols_#{current_user.id}")
    render :nothing => true
  end

  def get_tasklistcols
    colModel = Rails.cache.read("get_tasklistcols_#{current_user.id}")
    unless colModel
      defaultCol = Array.new
      defaultCol << {'name' => 'read', 'label' => ' ', 'formatter' => 'read', 'resizable' => false, 'sorttype' => 'boolean', 'width' => 16}
      defaultCol << {'name' => 'id', 'key' => true, 'sorttype' => 'int', 'width' => 30}
      defaultCol << {'name' => 'summary', 'width' => 300}
      defaultCol << {'name' => 'client', 'width' => 60}
      defaultCol << {'name' => 'milestone',  'width' => 60}
      defaultCol << {'name' => 'due', 'width' => 60, :label => 'target date'}
      defaultCol << {'name' => 'time', 'sorttype' => 'int', 'formatter' => 'tasktime', 'width' => 50, 'summaryType' => 'sum', 'summaryTpl' => '<b>{0}</b>'}
      defaultCol << {'name' => 'assigned', 'width' => 60}
      defaultCol << {'name' => 'resolution', 'width' => 60}
      defaultCol << {'name' => 'updated_at', 'width' => 60, 'label'=>'last comment date'}
      colModel = JSON.parse(current_user.preference('tasklistcols')) rescue nil
      colModel = Array.new if (! colModel.kind_of? Array)

      #ensure all default columns are in the model
      defaultCol.each do |attr|
        next if colModel.detect { |c| c['name'] == attr['name'] }
        colModel << attr
        logger.info "Property '#{attr['name']}' missing, adding to task list model."
      end

      #ensure all custom properties are in the model
      current_user.company.properties.each do |attr|
        next if colModel.detect { |c| c['name'] == attr.name.downcase }
        colModel << {'name' => attr.name.downcase}
        logger.info "Property '#{attr.name}' missing, adding to task list model."
      end
      Rails.cache.write("get_tasklistcols_#{current_user.id}", colModel)
    end
    order = session[:jqgrid_sort_order].nil? ?  'asc': session[:jqgrid_sort_order]
    column = session[:jqgrid_sort_column].nil? ?  'id' : session[:jqgrid_sort_column]
    render :json => { :colModel=>colModel, :currentSort=>{ :order=>order, :column => column}}
  end

  def set_task_grouping_preference
    current_user.preference_attributes = [ [ 'task_grouping', params[:id] ] ]
    render :nothing => true
  end

  ###
  # Returns the list to use for auto completes for user names.
  ###
  def auto_complete_for_user_name
    text = params[:term]
    if !text.blank?
    # the next line searches for names starting with given text OR surname (space started) starting with text of the active users
      @users = current_user.company.users.active.order('name').where('name LIKE ? OR name LIKE ?', text + '%', '% ' + text + '%').limit(50)
      render :json=> @users.collect{|user| {:value => user.name + ' (' + user.customer.name + ')', :id=> user.id} }.to_json
    else
      render :nothing=> true
    end
  end

private
  def protect_admin_area
    unless current_user.admin? or current_user.edit_clients?
      flash[:error] = _("Only admins can edit users.")
      redirect_to :action => 'edit_preferences'
      return false
    end
    true
  end

end
