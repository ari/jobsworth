# encoding: UTF-8
# Controller handling admin activities

class AdminStatsController < ApplicationController
  before_filter :authorize_user_is_admin

  def index
    @users = User.select([:created_at, :last_sign_in_at]).
             where("created_at > ?", Time.zone.now.beginning_of_year - 1.month)
    @users_total = User.count

    @projects = Project.select(:created_at).
                where("created_at > ?", Time.zone.now.beginning_of_year - 1.month)
    @projects_total = Project.count

    @tasks = Task.select(:created_at).
             where("created_at > ?", Time.zone.now.beginning_of_year - 1.month)
    @tasks_total = Task.count

    @last_50_users = User.limit(50).order("created_at desc")
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
end
