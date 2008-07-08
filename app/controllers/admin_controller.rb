# Controller handling admin activities

class AdminController < ApplicationController

  require_dependency 'RMagick'


  before_filter :authorize
  def index

  end

  def news
    @news = NewsItem.find(:all, :order => "created_at desc", :limit => 10)
  end

  def new_news
    @news = NewsItem.new
  end

  def create_news
    @news = NewsItem.new(params[:news])
    @news.save

    redirect_to :action => "news"
  end

  def edit_news
    @news = NewsItem.find(params[:id])
  end

  def update_news
    @news = NewsItem.find(params[:id])
    if @news.update_attributes(params[:news])
      flash['notice'] = 'NewsItem was successfully updated.'
      redirect_to :action => 'news'
    else
      render :action => 'edit_news'
    end
  end

  def delete_news
      NewsItem.find(params[:id]).destroy
      redirect_to :action => 'news'
  end

  # List all logos uploaded
  def logos
    @customers = Customer.find(:all)
  end

  # Show a single logo
  def show_logo
    @customer = Customer.find(params[:id])
    image = Magick::Image.read( @customer.logo_path ).first
    if image
      send_file @customer.logo_path, :filename => "logo", :type => image.mime_type, :disposition => 'inline'
    else
      render :nothing => true
    end
  end

  def stats
    @users_today      = User.count( :conditions => ["created_at > '#{tz.now.at_midnight.to_s(:db)}'"] )
    @users_yesterday  = User.count( :conditions => ["created_at > '#{tz.now.yesterday.at_midnight.to_s(:db)}' AND created_at < '#{tz.now.at_midnight.to_s(:db)}'"] )
    @users_this_week  = User.count( :conditions => ["created_at > '#{tz.now.beginning_of_week.at_midnight.to_s(:db)}'"] )
    @users_last_week  = User.count( :conditions => ["created_at > '#{1.week.ago.beginning_of_week.at_midnight.to_s(:db)}' AND created_at < '#{tz.now.beginning_of_week.at_midnight.to_s(:db)}'"] )
    @users_this_month = User.count( :conditions => ["created_at > '#{tz.now.beginning_of_month.at_midnight.to_s(:db)}'"] )
    @users_last_month = User.count( :conditions => ["created_at > '#{1.month.ago.beginning_of_month.at_midnight.to_s(:db)}' AND created_at < '#{tz.now.beginning_of_month.at_midnight.to_s(:db)}'"] )
    @users_this_year  = User.count( :conditions => ["created_at > '#{tz.now.beginning_of_year.at_midnight.to_s(:db)}'"] )
    @users_total      = User.count

    @projects_today      = Project.count( :conditions => ["created_at > '#{tz.now.at_midnight.to_s(:db)}'"] )
    @projects_yesterday  = Project.count( :conditions => ["created_at > '#{tz.now.yesterday.at_midnight.to_s(:db)}' AND created_at < '#{tz.now.at_midnight.to_s(:db)}'"] )
    @projects_this_week  = Project.count( :conditions => ["created_at > '#{tz.now.beginning_of_week.at_midnight.to_s(:db)}'"] )
    @projects_last_week  = Project.count( :conditions => ["created_at > '#{1.week.ago.beginning_of_week.at_midnight.to_s(:db)}' AND created_at < '#{tz.now.beginning_of_week.at_midnight.to_s(:db)}'"] )
    @projects_this_month = Project.count( :conditions => ["created_at > '#{tz.now.beginning_of_month.at_midnight.to_s(:db)}'"] )
    @projects_last_month = Project.count( :conditions => ["created_at > '#{1.month.ago.beginning_of_month.at_midnight.to_s(:db)}' AND created_at < '#{tz.now.beginning_of_month.at_midnight.to_s(:db)}'"] )
    @projects_this_year  = Project.count( :conditions => ["created_at > '#{tz.now.beginning_of_year.at_midnight.to_s(:db)}'"] )
    @projects_total      = Project.count

    @tasks_today      = Task.count( :conditions => ["created_at > '#{tz.now.at_midnight.to_s(:db)}'"] )
    @tasks_yesterday  = Task.count( :conditions => ["created_at > '#{tz.now.yesterday.at_midnight.to_s(:db)}' AND created_at < '#{tz.now.at_midnight.to_s(:db)}'"] )
    @tasks_this_week  = Task.count( :conditions => ["created_at > '#{tz.now.beginning_of_week.at_midnight.to_s(:db)}'"] )
    @tasks_last_week  = Task.count( :conditions => ["created_at > '#{1.week.ago.beginning_of_week.at_midnight.to_s(:db)}' AND created_at < '#{tz.now.beginning_of_week.at_midnight.to_s(:db)}'"] )
    @tasks_this_month = Task.count( :conditions => ["created_at > '#{tz.now.beginning_of_month.at_midnight.to_s(:db)}'"] )
    @tasks_last_month = Task.count( :conditions => ["created_at > '#{1.month.ago.beginning_of_month.at_midnight.to_s(:db)}' AND created_at < '#{tz.now.beginning_of_month.at_midnight.to_s(:db)}'"] )
    @tasks_this_year  = Task.count( :conditions => ["created_at > '#{tz.now.beginning_of_year.at_midnight.to_s(:db)}'"] )
    @tasks_total      = Task.count

    @logged_in_today      = User.count( :conditions => ["last_login_at > '#{tz.now.at_midnight.to_s(:db)}'"] )
    @logged_in_this_week  = User.count( :conditions => ["last_login_at > '#{tz.now.beginning_of_week.at_midnight.to_s(:db)}'"] )
    @logged_in_this_month = User.count( :conditions => ["last_login_at > '#{tz.now.beginning_of_month.at_midnight.to_s(:db)}'"] )
    @logged_in_this_year  = User.count( :conditions => ["last_login_at > '#{tz.now.beginning_of_year.at_midnight.to_s(:db)}'"] )

    @logged_in_now = User.count( :conditions => ["last_ping_at > '#{2.minutes.ago.utc.to_s(:db)}'"] )
    @last_50_users = User.find(:all, :limit => 50, :order => "created_at desc")
  end

  def authorize
    unless current_user.admin > 1
      redirect_to :controller => 'login', :action => 'login'
      return false
    end
    # Set current locale
    Localization.lang(current_user.locale || 'en_US')
  end

end
