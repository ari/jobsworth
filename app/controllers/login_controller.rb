# encoding: UTF-8
# Handle logins, as well as the portal pages
#
# The portal pages should probably be moved into
# a separate controller.
#
class LoginController < ApplicationController
  def index
    redirect_to :action => "login"
  end

  # Display the login page
  def login
       session[:user_id]=session["warden.user.user.key"][1]
    if session[:user_id]
      redirect_to :controller => 'activities', :action => 'list'
    else
      @company = company_from_subdomain
      @news ||= NewsItem.where("portal = ?", true).order("id desc").limit(3)
      render :action => 'login', :layout => false
    end
  end

  def logout  
    reset_session    
    redirect_to root_path
  end

  def validate
    if params[:forgot] == 'true'
      mail_password
      redirect_to :action => 'login'
      return
    end

    @user = User.new(params[:user])#
    @company = company_from_subdomain
    unless logged_in = @user.login(@company)
      flash[:notice] = "Username or password is wrong..."
      redirect_to :action => 'login'
      return
    end

    if params[:remember].to_i == 1
      session[:remember_until] = Time.now.utc + 2.weeks
      session[:expire_after] = session[:remember_until]
      session[:remember] = 1
    else
      session[:remember] = 0
      session[:remember_until] = Time.now.utc + 1.hour
    end

    logged_in.save  #
    session[:user_id] = logged_in.id

    session[:sheet] = nil
    session[:hide_dependencies] ||= "1"

    response.headers["Content-Type"] = 'text/html'

    redirect_from_last
  end

  private

  # Mail the User his/her credentials for all Users on the requested
  # email address
  def mail_password
    email = (params[:user] || {})[:username]
    if email.blank?
      flash[:notice] = "Enter your email address in the username field."
      return
    end

    EmailAddress.where(:email => email).each do |e|
       Signup::forgot_password(e.user).deliver
    end

    # tell user it was successful even if we didn't find the user, for security.
    flash[:notice] = "Mail sent"
  end


end
