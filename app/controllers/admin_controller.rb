# encoding: UTF-8
# Controller handling admin activities

class AdminController < ApplicationController

  before_filter :authorize
  def index

  end

  def news
    @news = NewsItem.order("created_at desc").limit(10)
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
    @customers = Customer.all
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
    @users_today      = User.where("created_at > '#{tz.now.at_midnight.to_s(:db)}'").count
    @users_yesterday  = User.where("created_at > '#{tz.now.yesterday.at_midnight.to_s(:db)}' AND created_at < '#{tz.now.at_midnight.to_s(:db)}'").count
    @users_this_week  = User.where("created_at > '#{tz.now.beginning_of_week.at_midnight.to_s(:db)}'").count
    @users_last_week  = User.where("created_at > '#{1.week.ago.beginning_of_week.at_midnight.to_s(:db)}' AND created_at < '#{tz.now.beginning_of_week.at_midnight.to_s(:db)}'").count
    @users_this_month = User.where("created_at > '#{tz.now.beginning_of_month.at_midnight.to_s(:db)}'").count
    @users_last_month = User.where("created_at > '#{1.month.ago.beginning_of_month.at_midnight.to_s(:db)}' AND created_at < '#{tz.now.beginning_of_month.at_midnight.to_s(:db)}'").count
    @users_this_year  = User.where("created_at > '#{tz.now.beginning_of_year.at_midnight.to_s(:db)}'").count
    @users_total      = User.count

    @projects_today      = Project.where("created_at > '#{tz.now.at_midnight.to_s(:db)}'").count
    @projects_yesterday  = Project.where("created_at > '#{tz.now.yesterday.at_midnight.to_s(:db)}' AND created_at < '#{tz.now.at_midnight.to_s(:db)}'").count
    @projects_this_week  = Project.where("created_at > '#{tz.now.beginning_of_week.at_midnight.to_s(:db)}'").count
    @projects_last_week  = Project.where("created_at > '#{1.week.ago.beginning_of_week.at_midnight.to_s(:db)}' AND created_at < '#{tz.now.beginning_of_week.at_midnight.to_s(:db)}'").count
    @projects_this_month = Project.where("created_at > '#{tz.now.beginning_of_month.at_midnight.to_s(:db)}'").count
    @projects_last_month = Project.where("created_at > '#{1.month.ago.beginning_of_month.at_midnight.to_s(:db)}' AND created_at < '#{tz.now.beginning_of_month.at_midnight.to_s(:db)}'").count
    @projects_this_year  = Project.where("created_at > '#{tz.now.beginning_of_year.at_midnight.to_s(:db)}'").count
    @projects_total      = Project.count

    @tasks_today      = Task.where("created_at > '#{tz.now.at_midnight.to_s(:db)}'").count
    @tasks_yesterday  = Task.where("created_at > '#{tz.now.yesterday.at_midnight.to_s(:db)}' AND created_at < '#{tz.now.at_midnight.to_s(:db)}'").count
    @tasks_this_week  = Task.where("created_at > '#{tz.now.beginning_of_week.at_midnight.to_s(:db)}'").count
    @tasks_last_week  = Task.where("created_at > '#{1.week.ago.beginning_of_week.at_midnight.to_s(:db)}' AND created_at < '#{tz.now.beginning_of_week.at_midnight.to_s(:db)}'").count
    @tasks_this_month = Task.where("created_at > '#{tz.now.beginning_of_month.at_midnight.to_s(:db)}'").count
    @tasks_last_month = Task.where("created_at > '#{1.month.ago.beginning_of_month.at_midnight.to_s(:db)}' AND created_at < '#{tz.now.beginning_of_month.at_midnight.to_s(:db)}'").count
    @tasks_this_year  = Task.where("created_at > '#{tz.now.beginning_of_year.at_midnight.to_s(:db)}'").count
    @tasks_total      = Task.count

    @logged_in_today      = User.where("last_login_at > '#{tz.now.at_midnight.to_s(:db)}'").count
    @logged_in_this_week  = User.where("last_login_at > '#{tz.now.beginning_of_week.at_midnight.to_s(:db)}'").count
    @logged_in_this_month = User.where("last_login_at > '#{tz.now.beginning_of_month.at_midnight.to_s(:db)}'").count
    @logged_in_this_year  = User.where("last_login_at > '#{tz.now.beginning_of_year.at_midnight.to_s(:db)}'").count

    @last_50_users = User.limit(50).order("created_at desc")
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
