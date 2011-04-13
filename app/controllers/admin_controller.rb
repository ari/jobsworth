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
    @users = User.select([:created_at, :last_sign_in_at]).where("created_at > ?", Time.zone.now.beginning_of_year - 1.month)
    @users_total = User.count

    @projects = Project.select(:created_at).where("created_at > ?", Time.zone.now.beginning_of_year - 1.month)
    @projects_total = Project.count

    @tasks = Task.select(:created_at).where("created_at > ?", Time.zone.now.beginning_of_year - 1.month)
    @tasks_total = Task.count

    @last_50_users = User.limit(50).order("created_at desc")
  end

  def authorize
    unless current_user.admin > 1
      redirect_to new_user_session_path
      return false
    end
    # Set current locale
    Localization.lang(current_user.locale || 'en_US')
  end

end
