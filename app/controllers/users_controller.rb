class UsersController < ApplicationController
  def index
    list
    render_action 'list'
  end

  def list
    if session[:user].admin == 10
      @user_pages, @users = paginate :user, :per_page => 50, :order => "last_login_at DESC"
    else
      @user_pages, @users = paginate :user, :per_page => 50, :conditions => ["company_id = ?", session[:user].company.id], :order => "name"
    end
  end

  def new
    @user = User.new
    @user.company = session[:user].company
    @user.time_zone = session[:user].time_zone
    @user.option_externalclients = 1;
    @user.option_tracktime = 1;
    @user.option_showcalendar = 1;
    @user.option_tooltips = 1;
  end

  def create
    @user = User.new(@params[:user])
    @user.company = session[:user].company
    @user.option_externalclients = 1;
    @user.option_tracktime = 1;
    @user.option_showcalendar = 1;
    @user.option_tooltips = 1;
    @user.date_format = "%d/%m/%Y"
    @user.time_format = "%H:%M"

    if @user.save
      flash['notice'] = _('User was successfully created. Remeber to give this user access to needed projects.')
      Signup::deliver_account_created(@user, session[:user]) rescue flash['notice'] += "<br/>" + _("Error sending creation email. Account still created.")
      redirect_to :action => 'list'
    else
      render_action 'new'
    end
  end

  def edit
    @user = User.find(@params[:id], :conditions => ["company_id = ?", session[:user].company_id])
  end

  def update
    @user = User.find(@params[:id], :conditions => ["company_id = ?", session[:user].company_id])
    if @user.update_attributes(@params[:user])
      session[:user] = @user if @user.id == session[:user].id
      flash['notice'] = _('User was successfully updated.')
      redirect_to :action => 'list'
    else
      render_action 'edit'
    end
  end

  def edit_preferences
    @user = User.find(@session[:user].id)
  end

  def update_preferences
    @user = User.find(@params[:id], :conditions => ["company_id = ?", session[:user].company_id])
    if @user.update_attributes(@params[:user])
      session[:user] = @user if @user.id == session[:user].id
      Localization.lang = session[:user].locale || 'en_US'
      flash['notice'] = _('Preferences successfully updated.')
      redirect_to :controller => 'activities', :action => 'list'
    else
      render_action 'edit'
    end
  end

  def destroy
    @user = User.find(@params[:id], :conditions => ["company_id = ?", session[:user].company_id])
    @user.destroy
    redirect_to :action => 'list'
  end

  # Used while debugging
  def impersonate
    if session[:user].admin > 9
      @user = User.find(@params[:id])
      if @user != nil
        session[:user] = @user
        session[:project] = nil
        session[:sheet] = nil
      end
    end
    redirect_to :action => 'list'
  end

  def update_seen_news
    if request.xhr?
      @user = User.find(session[:user].id)
      unless @user.nil?
        @user.seen_news_id = params[:id]
        @user.save
        session[:user].seen_news_id = params[:id]
      end
    end
    render :nothing => true
  end

end
