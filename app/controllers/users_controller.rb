class UsersController < ApplicationController
  require_dependency 'RMagick'


  def index
    list
    render :action => 'list'
  end

  def list
    if current_user.admin > 0
      @users = User.paginate(:order => "users.name", :conditions => ["users.company_id = ?", current_user.company_id], :page => params[:page], :include => { :projects => :customer } )
    else
      redirect_to :action => 'edit_preferences'
    end
  end

  def new
    if current_user.admin == 0
      flash['notice'] = _("Only admins can edit users.")
      redirect_to :action => 'edit_preferences'
      return
    end

    @user = User.new
    @user.company_id = current_user.company_id
    @user.time_zone = current_user.time_zone
    @user.option_externalclients = 1;
    @user.option_tracktime = 1;
    @user.option_tooltips = 1;
  end

  def create
    if current_user.admin == 0
      flash['notice'] = _("Only admins can edit users.")
      redirect_to :action => 'edit_preferences'
      return
    end

    @user = User.new(params[:user])
    @user.company_id = current_user.company_id
    @user.date_format = "%d/%m/%Y"
    @user.time_format = "%H:%M"

    if @user.save
      
      if params[:copy_user].to_i > 0
        u = current_user.company.users.find(params[:copy_user])
        u.project_permissions.each do |perm|
          p = perm.clone
          p.user = @user
          p.save
        end
      end
      
      flash['notice'] = _('User was successfully created. Remember to give this user access to needed projects.')
      Signup::deliver_account_created(@user, current_user, params['welcome_message']) rescue flash['notice'] += "<br/>" + _("Error sending creation email. Account still created.")
      redirect_to :action => 'edit', :id => @user
    else
      render :action => 'new'
    end
  end

  def edit
    if current_user.admin == 0
      flash['notice'] = _("Only admins can edit users.")
      redirect_to :action => 'edit_preferences'
      return
    end
    @user = User.find(params[:id], :conditions => ["company_id = ?", current_user.company_id])
  end

  def update
    if current_user.admin == 0
      flash['notice'] = _("Only admins can edit users.")
      redirect_to :action => 'edit_preferences'
      return
    end

    @user = User.find(params[:id], :conditions => ["company_id = ?", current_user.company_id])

    if params[:user][:admin].to_i > current_user.admin
      params[:user][:admin] = current_user.admin
    end
    
    if @user.update_attributes(params[:user])
      flash['notice'] = _('User was successfully updated.')
      redirect_to :action => 'list'
    else
      render :action => 'edit'
    end
  end

  def edit_preferences
    @user = current_user
  end

  def update_preferences
    @user = User.find(params[:id], :conditions => ["company_id = ?", current_user.company_id])
    if @user.update_attributes(params[:user])
      flash['notice'] = _('Preferences successfully updated.')
      redirect_to :controller => 'activities', :action => 'list'
    else
      render :action => 'edit'
    end
  end

  def destroy
    if current_user.admin == 0
      flash['notice'] = _("Only admins can delete users")
      redirect_to :action => 'edit_preferences'
      return
    end

    if current_user.id == params[:id].to_i
      flash['notice'] = _("You can't delete yourself.")
      redirect_to :action => 'list'
      return
    end

    @user = User.find(params[:id], :conditions => ["company_id = ?", current_user.company_id])
    ActiveRecord::Base.connection.execute("UPDATE tasks set creator_id = NULL WHERE company_id = #{current_user.company_id} AND creator_id = #{@user.id}")
    @user.destroy
    redirect_to :action => 'list'
  end

  # Used while debugging
  def impersonate
    if current_user.admin > 9
      @user = User.find(params[:id])
      if @user != nil
        current_user = @user
        session[:user_id] = @user.id
        session[:project] = nil
        session[:sheet] = nil
      end
    end
    redirect_to :action => 'list'
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
      flash['notice'] = _('No file selected.')
      redirect_from_last
      return
    end
    filename = params['user']['tmp_file'].original_filename
    @user = User.find(params[:id],  :conditions => ["company_id = ?", current_user.company_id])

    if @user.avatar?
      File.delete(@user.avatar_path) rescue begin
                                                flash['notice'] = _("Permission denied while deleting old avatar.")
                                                redirect_to :action => 'edit_preferences'
                                                return
                                              end

    end

    if !File.directory?(@user.path)
      Dir.mkdir(@user.path, 0755) rescue begin
                                                flash['notice'] = _('Unable to create storage directory.')
                                                redirect_to :action => 'edit_preferences'
                                                return
                                              end
    end

    unless params['user']['tmp_file'].size > 0
      flash['notice'] = _('Empty file uploaded.')
      redirect_to :action => 'edit_preferences'
      return
    end

    File.open(@user.avatar_path, "wb", 0755) { |f| f.write( params['user']['tmp_file'].read ) } rescue begin
                                                                                                               flash['notice'] = _("Permission denied while saving file.")
                                                                                                               redirect_to :action => 'edit_preferences'
                                                                                                               return
                                                                                                             end


    if( File.size?(@user.avatar_path).to_i > 0 )
      image = Magick::Image.read( @user.avatar_path ).first
      image.format = 'JPEG'

      if image.columns > image.rows
        scale = 25.0 / image.columns
        large_scale = 50.0 / image.columns
      else
        scale = 25.0 / image.rows
        large_scale = 50.0 / image.rows
      end

      if image.rows * scale > 25.0
        scale = 25.0 / image.rows
        large_scale = 50.0 / image.rows
      end

      large = image.scale(large_scale)
      small = image.scale(scale)

      begin
        File.open(@user.avatar_path, "wb", 0777) { |f| f.write( small.to_blob ) }
        File.open(@user.avatar_large_path, "wb", 0777) { |f| f.write( large.to_blob ) }
      rescue
        image = nil
        large = nil
        small = nil
        GC.start

        flash['notice'] = _("Permission denied while saving resized file.")
        redirect_to :action => 'edit_preferences'
        return
      end
      image = nil
      large = nil
      small = nil
      GC.start
    else
      flash['notice'] = _('Empty file.')
      begin
        File.delete(@user.avatar_path)
        File.delete(@user.avatar_large_path)
      rescue
      end
      redirect_from_last
      return
    end
    GC.start
    flash['notice'] = _('Avatar successfully uploaded.')
    redirect_from_last
  end

  def delete_avatar
    @user = User.find(params[:id], :conditions => ["company_id = ?", current_user.company_id] )
    unless @user.nil?
      File.delete(@user.avatar_path) rescue begin end
      File.delete(@user.avatar_large_path) rescue begin end
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


end
