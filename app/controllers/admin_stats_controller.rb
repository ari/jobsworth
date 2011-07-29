# encoding: UTF-8
# Controller handling admin activities

class AdminStatsController < ApplicationController
  before_filter :authorize_user_is_admin

  def index
    @users_from_this_year = User.from_this_year
    @users_total          = User.count

    @projects_from_this_year = Project.from_this_year
    @projects_total          = Project.count

    @tasks_from_this_year = Task.from_this_year
    @tasks_total          = Task.count

    @last_50_users = User.recent_users
  end
end
