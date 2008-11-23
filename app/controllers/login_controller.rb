# Handle logins, as well as the portal pages
#
# The portal pages should probably be moved into
# a separate controller.
#
class LoginController < ApplicationController

  layout 'login'

  def index
    @user = User.new
    render :action => 'login'

    @news ||= NewsItem.find(:all, :conditions => "portal = 1", :order => "id desc", :limit => 3)
  end

  def screenshots
  end

  def policy
  end

  def terms
  end
  
  def about
  end

  def login

    subdomain = 'www'
    subdomain = request.subdomains.first if request.subdomains
    if session[:user_id]
      redirect_to :controller => 'activities', :action => 'list'
    else
      if subdomain != 'www'
        @company = Company.find(:first, :conditions => ["subdomain = ?", subdomain])
        if !@company.nil?
          render :action => 'login', :layout => false
        else
          redirect_to "http://www.#{$CONFIG[:domain]}"
        end
      end
    end   
    @news ||= NewsItem.find(:all, :conditions => "portal = 1", :order => "id desc", :limit => 3)
  end

  def logout
    # Mark user as logged out
    ActiveRecord::Base.connection.execute("update users set last_ping_at = NULL, last_seen_at = NULL where id = #{current_user.id}")

    current_user.last_seen_at = nil
    current_user.last_ping_at = nil
    
    # Let other logged in Users in same Company know that User logged out.
    Juggernaut.send("do_execute(#{current_user.id}, \"Element.update('flash_message', '#{current_user.username} logged out..');Element.show('flash'); new Effect.Highlight('flash_message', {duration:2.0});\");", ["info_#{current_user.company_id}"])

    chat_update = render_to_string :update do |page|
      page << "if($('presence-online')) {"
      page.replace_html 'presence-online', (online_users).to_s
      page << "if($('presence-toggle-#{current_user.dom_id}')) {"
      page << "$('presence-img-#{current_user.dom_id}').src=\"#{current_user.online_status_icon}\";"
      page << "}"
      page << "}"
    end
    Juggernaut.send("do_execute(#{current_user.id}, '#{double_escape(chat_update)}');", ["info_#{current_user.company_id}"])

    response.headers["Content-Type"] = 'text/html'

    session[:user_id] = nil
    session[:project] = nil
    session[:sheet] = nil
    session[:filter_user] = nil
    session[:filter_milestone] = nil
    session[:filter_hidden] = nil
    session[:filter_status] = nil
    session[:filter_type] = nil
    session[:filter_severity] = nil
    session[:filter_priority] = nil
    session[:group_tags] = nil
    session[:channels] = nil
    session[:hide_dependencies] = nil
    session[:remember_until] = nil
    session[:redirect] = nil
    session[:history] = nil
    redirect_to "/"
  end

  def validate
    @user = User.new(params[:user])
    subdomain = 'www'
    subdomain = request.subdomains.first if request.subdomains
    if logged_in = @user.login(subdomain)
      logged_in.last_login_at = Time.now.utc
      
      if params[:remember].to_i == 1
        session[:remember_until] = Time.now.utc + 1.month
        session[:remember] = 1
      else 
        session[:remember] = 0
        session[:remember_until] = Time.now.utc + 1.hour
      end
      logged_in.last_seen_at = Time.now.utc
      logged_in.last_ping_at = Time.now.utc

      logged_in.save
      session[:user_id] = logged_in.id
      
      session[:sheet] = nil
      session[:filter_user] ||= current_user.id.to_s
      session[:filter_project] ||= "0"
      session[:filter_milestone] ||= "0"
      session[:filter_status] ||= "0"
      session[:filter_hidden] ||= "0"
      session[:filter_type] ||= "-1"
      session[:filter_severity] ||= "-10"
      session[:filter_priority] ||= "-10"
      session[:hide_dependencies] ||= "1"
      session[:filter_customer] ||= "0"
      
      # Let others know User logged in
      Juggernaut.send("do_execute(#{logged_in.id}, \"Element.update('flash_message', '#{logged_in.username} logged in..');Element.show('flash');new Effect.Highlight('flash_message',{duration:2.0});\");", ["info_#{logged_in.company_id}"])

      chat_update = render_to_string :update do |page|
        page << "if($('presence-online')) {"
        page.replace_html 'presence-online', (online_users).to_s
        page << "if($('presence-toggle-#{logged_in.dom_id}')) {"
        page << "$('presence-img-#{logged_in.dom_id}').src=\"#{logged_in.online_status_icon}\";"
        page << "}"
        page << "}"
      end
      
      Juggernaut.send("do_execute(#{logged_in.id}, '#{double_escape(chat_update)}');", ["info_#{logged_in.company_id}"])

      response.headers["Content-Type"] = 'text/html'
      
      redirect_from_last
    else
      flash[:notice] = "Username or password is wrong..."
      redirect_to :action => 'login'
    end
  end

  def forgotten_password

  end

  # Mail the User his/her credentials for all Users on the requested
  # email address
  def take_forgotten
    flash[:notice] = ""
    error = 0

    if params[:email].nil? || params[:email].length == 0
      flash[:notice] += "* Enter your email<br/>"
      error = 1
    elsif User.count( :conditions => ["email = ?", params[:email]]) == 0
      flash[:notice] += "* No such email<br/>"
      error = 1
    end

    if( error == 0 )
      @users = User.find(:all, :conditions => ["email = ?", params[:email]])
      @users.each do |u|
         Signup::deliver_forgot_password(u)
      end
    end

    flash[:notice] = "Mail sent"
    redirect_to :action => 'login'
  end


  def signup
    @user = User.new
  end

  def take_signup

    error = 0

    unless params[:username]
      @user = User.new
      @company = Company.new
      render :action => 'signup'
      return
    end

    flash[:notice] = ""


    # FIXME: Use models validation instead
    if params[:username].length == 0
      flash[:notice] += "* Enter username<br/>"
      error = 1
    end

    if params[:password].length == 0
      flash[:notice] += "* Enter password<br/>"
      error = 1
    end

    if params[:password_again].length == 0
      flash[:notice] += "* Enter password again<br/>"
      error = 1
    end

    if params[:password_again] != params[:password]
      flash[:notice] += "* Password and Password Again don't match<br/>"
      error = 1
    end

    if params[:name].length == 0
      flash[:notice] += "* Enter your name<br/>"
      error = 1
    end

    if params[:email].length == 0
      flash[:notice] += "* Enter your email<br/>"
      error = 1
    end

    if params[:company].length == 0
      flash[:notice] += "* Enter your company name<br/>"
      error = 1
    end

    if params[:subdomain].length == 0
      flash[:notice] += "* Enter your preferred URL for company access<br/>"
      error = 1
    elsif params[:subdomain].match(/[^a-zA-Z0-9-]/) != nil
      flash[:notice] += "* Login URL can only contain letters, numbers, and hyphens, no spaces."
      error = 1
    elsif Company.count( :conditions => ["subdomain = ?", params[:subdomain]]) > 0
      flash[:notice] += "* Login url already taken. Please choose another one."
      error = 1
    end

    if error == 0
      # Create the User and Company
      @user = User.new
      @company = Company.new

      @user.name = params[:name]
      @user.username = params[:username]
      @user.password = params[:password]
      @user.email = params[:email]
      @user.time_zone = params[:user][:time_zone]
      @user.locale = params[:user][:locale]
      @user.option_externalclients = 1
      @user.option_tracktime = 1
      @user.option_tooltips = 1
      @user.date_format = "%d/%m/%Y"
      @user.time_format = "%H:%M"
      @user.admin = 1

      @company.name = params[:company]
      @company.contact_email = params[:email]
      @company.contact_name = params[:name]
      @company.subdomain = params[:subdomain].downcase.strip


      if @company.save
        @customer = Customer.new
        @customer.name = @company.name

        @company.customers << @customer
        @company.users << @user

        Signup::deliver_signup(@user, @company) rescue flash[:notice] = "Error sending registration email. Account still created.<br/>"
        redirect_to "http://#{@company.subdomain}.#{$CONFIG[:domain]}"
      end

    else
      render :action => 'signup'
    end

  end

  def company_check
    if params[:company].blank?
      render :text => "<img src=\"/images/delete.png\" border=\"0\" style=\"vertical-align:middle;\"/> <small>Please choose a name.</small>"
    else
      companies = Company.count( :conditions => ["name = ?", params[:company]])
      if companies > 0
        render :text => "<img src=\"/images/error.png\" border=\"0\" style=\"vertical-align:middle;\"/> <small>Company name already esists. Do you really want to create a duplicate company?</small>"
      else
        render :text => "<img src=\"/images/accept.png\" border=\"0\" style=\"vertical-align:middle;\"/> <small>Name OK</small>"
      end
    end
  end

  def subdomain_check
    if params[:subdomain].nil? || params[:subdomain].empty?
      render :text => "<img src=\"/images/delete.png\" border=\"0\" style=\"vertical-align:middle;\"/> <small>Please choose a domain.</small>"
    else
      subdomain = Company.count( :conditions => ["subdomain = ?", params[:subdomain]])
      if %w( www forum wiki repo mail ftp static01 new lists static ).include?( params[:subdomain].downcase )
        subdomain = 1
      end

      if params[:subdomain].match(/[^a-zA-Z0-9-]/) != nil
        render :text => "<img src=\"/images/delete.png\" border=\"0\" style=\"vertical-align:middle;\"/> <small>Domain can only contain letters, numbers, and hyphens, no spaces.</small>"

      elsif subdomain > 0
        render :text => "<img src=\"/images/delete.png\" border=\"0\" style=\"vertical-align:middle;\"/> <small>Domain already in use, please choose a different one.</small>"
      else
        render :text => "<img src=\"/images/accept.png\" border=\"0\" style=\"vertical-align:middle;\"/> <small>Domain OK</small>"
      end
    end
  end

  def shortlist_auth
    return if params[:id].nil? || params[:id].empty?
    user = User.find(:first, :conditions => ["autologin = ?", params[:id]])

    if user.nil?
      render :nothing => true, :layout => false
      return
    end

    session[:user_id] = user.id
    session[:remember_until] = Time.now.utc + ( session[:remember].to_i == 1 ? 1.month : 1.hour )
    session[:redirect] = nil
    authorize

    redirect_to :controller => 'tasks', :action => 'shortlist'

  end

end
