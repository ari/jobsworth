class AdminController < ApplicationController

  require 'RMagick'

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
    @news = NewsItem.find(@params[:id])
  end

  def update_news
    @news = NewsItem.find(@params[:id])
    if @news.update_attributes(@params[:news])
      flash['notice'] = 'NewsItem was successfully updated.'
      redirect_to :action => 'news'
    else
      render_action 'edit_news'
    end
  end

  def delete_news
      NewsItem.find(@params[:id]).destroy
      redirect_to :action => 'news'
  end

  def logos
    @customers = Customer.find(:all, :conditions => ["binary_id > 0 "])
  end

  def show_logo
    @customer = Customer.find(@params[:id])
    image = Magick::Image.from_blob( @customer.binary.data ).first
    send_data image.to_blob, :filename => "logo", :type => image.mime_type, :disposition => 'inline'
  end

  def stats
    @users_today = User.count( ["created_at > '#{tz.now.at_midnight.strftime("%Y-%m-%d %H:%M:%S")}'"] )
    @users_yesterday = User.count( ["created_at > '#{tz.now.yesterday.at_midnight.strftime("%Y-%m-%d %H:%M:%S")}' AND created_at < '#{tz.now.at_midnight.strftime("%Y-%m-%d %H:%M:%S")}'"] )
    @users_this_week = User.count( ["created_at > '#{tz.now.beginning_of_week.at_midnight.strftime("%Y-%m-%d %H:%M:%S")}'"] )
    @users_last_week = User.count( ["created_at > '#{1.week.ago.beginning_of_week.at_midnight.strftime("%Y-%m-%d %H:%M:%S")}' AND created_at < '#{tz.now.beginning_of_week.at_midnight.strftime("%Y-%m-%d %H:%M:%S")}'"] )
    @users_this_month = User.count([ "created_at > '#{tz.now.beginning_of_month.at_midnight.strftime("%Y-%m-%d %H:%M:%S")}'"] )
    @users_last_month = User.count([ "created_at > '#{1.month.ago.beginning_of_month.at_midnight.strftime("%Y-%m-%d %H:%M:%S")}' AND created_at < '#{tz.now.beginning_of_month.at_midnight.strftime("%Y-%m-%d %H:%M:%S")}'"] )
    @users_this_year = User.count( ["created_at > '#{tz.now.beginning_of_year.at_midnight.strftime("%Y-%m-%d %H:%M:%S")}'"] )
    @users_total = User.count

    @projects_today = Project.count( ["created_at > '#{tz.now.at_midnight.strftime("%Y-%m-%d %H:%M:%S")}'"] )
    @projects_yesterday = Project.count( ["created_at > '#{tz.now.yesterday.at_midnight.strftime("%Y-%m-%d %H:%M:%S")}' AND created_at < '#{tz.now.at_midnight.strftime("%Y-%m-%d %H:%M:%S")}'"] )
    @projects_this_week = Project.count( ["created_at > '#{tz.now.beginning_of_week.at_midnight.strftime("%Y-%m-%d %H:%M:%S")}'"] )
    @projects_last_week = Project.count( ["created_at > '#{1.week.ago.beginning_of_week.at_midnight.strftime("%Y-%m-%d %H:%M:%S")}' AND created_at < '#{tz.now.beginning_of_week.at_midnight.strftime("%Y-%m-%d %H:%M:%S")}'"] )
    @projects_this_month = Project.count([ "created_at > '#{tz.now.beginning_of_month.at_midnight.strftime("%Y-%m-%d %H:%M:%S")}'"] )
    @projects_last_month = Project.count([ "created_at > '#{1.month.ago.beginning_of_month.at_midnight.strftime("%Y-%m-%d %H:%M:%S")}' AND created_at < '#{tz.now.beginning_of_month.at_midnight.strftime("%Y-%m-%d %H:%M:%S")}'"] )
    @projects_this_year = Project.count( ["created_at > '#{tz.now.beginning_of_year.at_midnight.strftime("%Y-%m-%d %H:%M:%S")}'"] )
    @projects_total = Project.count

    @tasks_today = Task.count( ["created_at > '#{tz.now.at_midnight.strftime("%Y-%m-%d %H:%M:%S")}'"] )
    @tasks_yesterday = Task.count( ["created_at > '#{tz.now.yesterday.at_midnight.strftime("%Y-%m-%d %H:%M:%S")}' AND created_at < '#{tz.now.at_midnight.strftime("%Y-%m-%d %H:%M:%S")}'"] )
    @tasks_this_week = Task.count( ["created_at > '#{tz.now.beginning_of_week.at_midnight.strftime("%Y-%m-%d %H:%M:%S")}'"] )
    @tasks_last_week = Task.count( ["created_at > '#{1.week.ago.beginning_of_week.at_midnight.strftime("%Y-%m-%d %H:%M:%S")}' AND created_at < '#{tz.now.beginning_of_week.at_midnight.strftime("%Y-%m-%d %H:%M:%S")}'"] )
    @tasks_this_month = Task.count([ "created_at > '#{tz.now.beginning_of_month.at_midnight.strftime("%Y-%m-%d %H:%M:%S")}'"] )
    @tasks_last_month = Task.count([ "created_at > '#{1.month.ago.beginning_of_month.at_midnight.strftime("%Y-%m-%d %H:%M:%S")}' AND created_at < '#{tz.now.beginning_of_month.at_midnight.strftime("%Y-%m-%d %H:%M:%S")}'"] )
    @tasks_this_year = Task.count( ["created_at > '#{tz.now.beginning_of_year.at_midnight.strftime("%Y-%m-%d %H:%M:%S")}'"] )
    @tasks_total = Task.count

    @logged_in_today = User.count( ["last_login_at > '#{tz.now.at_midnight.strftime("%Y-%m-%d %H:%M:%S")}'"] )
    @logged_in_this_week = User.count( ["last_login_at > '#{tz.now.beginning_of_week.at_midnight.strftime("%Y-%m-%d %H:%M:%S")}'"] )
    @logged_in_this_month = User.count([ "last_login_at > '#{tz.now.beginning_of_month.at_midnight.strftime("%Y-%m-%d %H:%M:%S")}'"] )
    @logged_in_this_year = User.count( ["last_login_at > '#{tz.now.beginning_of_year.at_midnight.strftime("%Y-%m-%d %H:%M:%S")}'"] )

    @logged_in_now = User.count( ["last_ping_at > '#{2.minutes.ago.utc.strftime("%Y-%m-%d %H:%M:%S")}'"] )

    @last_10_users = User.find(:all, :limit => 10, :order => "created_at desc")
  end

  def authorize
    unless session[:user].admin > 1
      redirect_to :controller => 'login', :action => 'login'
      return false
    end
  end

end
