class InstallController < ApplicationController
  layout "install"

  skip_before_filter :install, :authorize
  before_filter :check_can_install

  def index
  end

  def create
    @company = Company.new(params[:company])
    @company.subdomain = @company.name.to_s.parameterize("_")

    @user = User.new(params[:user])
    @user.admin = true
    @user.seen_welcome = true
    @user.company = @company
    @user.username = @user.name

    if @company.valid? and @user.valid?
      customer = @company.customers.build(:name => @company.name)
      @user.customer = customer

      @company.save
      @user.save

      project_params = params[:project].merge(:customer => customer)
      project = @company.projects.create!(project_params)

      perm = project.project_permissions.build(:user => @user, :company => @company)
      perm.set("all")
      perm.save!

      session[:user_id] = @user.id

      prompts_params = { 
        :name => "The name of your first task",
        :description => "A longer description of your first task",
        :project_id => project.id
      }
      redirect_to url_for(:controller => "tasks", :action => "new",
                          :task => prompts_params)
    else
      render :action => "index"
    end
  end

  private

  def check_can_install
    if Company.count > 0
      redirect_to "/tasks/list" and return false
    else
      return true
    end
  end
end
