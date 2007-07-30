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
  end

  def login
    subdomain = 'www'
    subdomain = request.subdomains.first if request.subdomains

    if subdomain != 'www'
      @company = Company.find(:first, :conditions => ["subdomain = ?", subdomain])
      if !@company.nil?
        render :action => 'login', :layout => false
      else
        redirect_to "http://www.#{$CONFIG[:domain]}"
      end
    end
  end

  def logout
    # Mark user as logged out
    ActiveRecord::Base.connection.execute("update users set last_ping_at = NULL where id = #{session[:user].id}")

    # Let other logged in Users in same Company know that User logged out.
    Juggernaut.send("do_execute(#{session[:user].id}, \"Element.update('flash_message', '#{session[:user].username} logged out..');Element.show('flash'); new Effect.Highlight('flash_message', {duration:2.0});\");", ["info_#{session[:user].company_id}"])

    session[:user] = nil
    session[:project] = nil
    session[:sheet] = nil
    session[:filter_user] = nil
    session[:filter_milestone] = nil
    session[:filter_hidden] = nil
    session[:filter_status] = nil
    session[:group_tags] = nil
    session[:channels] = nil
    redirect_to "/"
  end

  def validate
    @user = User.new(@params[:user])
    subdomain = 'www'
    subdomain = request.subdomains.first if request.subdomains
    if logged_in = @user.login(subdomain)
      logged_in.last_login_at = Time.now.utc
      logged_in.last_seen_at = Time.now.utc
      logged_in.save
      session[:user] = logged_in

      if @sheet = Sheet.find(:first, :conditions => ["user_id = ? ", logged_in.id])
        session[:sheet] = @sheet
      end

      # Auto-filter by User if more than one Users are registered for
      # Users Company
      if User.count("company_id = #{logged_in.company_id}") > 1
        session[:filter_user] = logged_in.id.to_s
      else
        session[:filter_user] = "0"
      end

      session[:filter_hidden] = logged_in.last_filter.to_s
      session[:filter_status] = "0"
      session[:group_tags] = "0"

      unless logged_in.last_milestone_id.nil? && session[:project].nil?
        begin
          milestone = session[:project].milestones.find(logged_in.last_milestone_id)
          session[:filter_milestone] = milestone.id.to_s
        rescue
          session[:filter_milestone] = "0"
        end
      end

      # Let others know User logged in
      Juggernaut.send("do_execute(#{session[:user].id}, \"Element.update('flash_message', '#{session[:user].username} logged in..');Element.show('flash');new Effect.Highlight('flash_message',{duration:2.0});\");", ["info_#{session[:user].company_id}"])

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

    if @params[:email].length == 0
      flash[:notice] += "* Enter your email<br/>"
      error = 1
    elsif User.count(["email = ?", @params[:email]]) == 0
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

    unless @params[:username]
      @user = User.new
      @company = Company.new
      render :action => 'signup'
      return
    end

    flash[:notice] = ""


    # FIXME: Use models validation instead
    if @params[:username].length == 0
      flash[:notice] += "* Enter username<br/>"
      error = 1
    end

    if @params[:password].length == 0
      flash[:notice] += "* Enter password<br/>"
      error = 1
    end

    if @params[:password_again].length == 0
      flash[:notice] += "* Enter password again<br/>"
      error = 1
    end

    if @params[:password_again] != @params[:password]
      flash[:notice] += "* Password and Password Again don't match<br/>"
      error = 1
    end

    if @params[:name].length == 0
      flash[:notice] += "* Enter your name<br/>"
      error = 1
    end

    if @params[:email].length == 0
      flash[:notice] += "* Enter your email<br/>"
      error = 1
    end

    if @params[:company].length == 0
      flash[:notice] += "* Enter your company name<br/>"
      error = 1
    elsif Company.count(["name = ?", @params[:company]]) > 0
      flash[:notice] += "* Company name taken. If someone at your company is using Clocking IT, have them create an account for you so you end up in the same company.<br/>"
      error = 1
    end

    if @params[:subdomain].length == 0
      flash[:notice] += "* Enter your preferred URL for company access<br/>"
      error = 1
    elsif @params[:subdomain].match(/[\W _]/) != nil
      flash[:notice] += "* Login URL can only contain letters and numbers, no spaces."
      error = 1
    elsif Company.count(["subdomain = ?", @params[:subdomain]]) > 0
      flash[:notice] += "* Login url already taken. Please choose another one."
      error = 1
    end

    if error == 0
      # Create the User and Company
      @user = User.new
      @company = Company.new

      @user.name = @params[:name]
      @user.username = @params[:username]
      @user.password = @params[:password]
      @user.email = @params[:email]
      @user.time_zone = @params[:user][:time_zone]
      @user.locale = @params[:user][:locale]
      @user.option_externalclients = 1
      @user.option_tracktime = 1
      @user.option_showcalendar = 1
      @user.option_tooltips = 1
      @user.date_format = "%d/%m/%Y"
      @user.time_format = "%H:%M"
      @user.admin = 1

      @company.name = @params[:company]
      @company.contact_email = @params[:email]
      @company.contact_name = @params[:name]
      @company.subdomain = @params[:subdomain].downcase


      if @company.save
        @customer = Customer.new
        @customer.name = @company.name

        @company.customers << @customer
        @company.users << @user

        Signup::deliver_signup(@user, @company) rescue flash[:notice] = "Error sending registration email. Account still created.<br/>"
        redirect_to "http://#{@company.subdomain}.#{$CONFIG[:domain]}"
      end

    else
      render_action 'signup'
    end

  end

  def company_check
    companies = Company.count(["name = ?", params[:company]])
    if params[:company].empty?
      render :inline => "<img src=\"/images/delete.png\" border=\"0\" style=\"vertical-align:middle;\"/> <small>Please choose a name.</small>"
    else
      if companies > 0
        render :inline => "<img src=\"/images/delete.png\" border=\"0\" style=\"vertical-align:middle;\"/> <small>Name already taken, have someone from that company create your account, or choose a different name.</small>"
      else
        render :inline => "<img src=\"/images/accept.png\" border=\"0\" style=\"vertical-align:middle;\"/> <small>Name OK</small>"
      end
    end
  end

  def subdomain_check
    if params[:subdomain].nil? || params[:subdomain].empty?
      render :inline => "<img src=\"/images/delete.png\" border=\"0\" style=\"vertical-align:middle;\"/> <small>Please choose a domain.</small>"
    else
      subdomain = Company.count(["subdomain = ?", params[:subdomain]])
      if %w( www forum wiki repo mail ftp static01 ).include?( params[:subdomain].downcase )
        subdomain = 1
      end

      if params[:subdomain].match(/[\W _]/) != nil
        render :inline => "<img src=\"/images/delete.png\" border=\"0\" style=\"vertical-align:middle;\"/> <small>Domain can only contain letters and numbers, no spaces.</small>"

      elsif subdomain > 0
        render :inline => "<img src=\"/images/delete.png\" border=\"0\" style=\"vertical-align:middle;\"/> <small>Domain already taken, choose a different one.</small>"
      else
        render :inline => "<img src=\"/images/accept.png\" border=\"0\" style=\"vertical-align:middle;\"/> <small>Domain OK</small>"
      end
    end
  end

end
