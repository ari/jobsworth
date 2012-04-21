# encoding: UTF-8
# Handle CRUD dealing with Customers

class CustomersController < ApplicationController
  before_filter :authorize_user_can_create_customers, :only => [:new, :create]
  before_filter :authorize_user_can_edit_customers,   :only => [:edit, :update, :destroy]
  before_filter :authorize_user_can_read_customers,   :only => [:show]

  def show
    @customer = Customer.from_company(current_user.company_id).find(params[:id])
  end

  def new
    @customer = current_user.company.customers.new
  end

  def create
    @customer         = Customer.new(params[:customer])
    @customer.company = current_user.company

    if @customer.save
      flash[:success] = _('Customer was successfully created.')
      redirect_to root_path
    else
      flash[:error] = @customer.errors.full_messages.join(".")
      render :new
    end
  end

  def edit
    @customer = Customer.from_company(current_user.company_id).where(:id => params[:id]).includes(:projects).first
  end

  def update
    @customer = Customer.from_company(current_user.company_id).find(params[:id])

    if @customer.update_attributes(params[:customer])
      flash[:success] = _('Customer was successfully updated.')
      redirect_to :action => :edit, :id => @customer.id
    else
      render :edit
    end
  end  

  def destroy
    @customer = Customer.from_company(current_user.company_id).find(params[:id])

    if @customer.has_projects?
      flash[:error] = 
        _("Please delete all projects for #{@customer.name} before deleting it.")

    #TODO: What the ... ?
    elsif @customer.name == current_user.company.name
      flash[:error] = _("You can't delete your own company.")

    else
      flash[:success] = _("Customer was successfully deleted.")
      @customer.destroy
    end

    redirect_to root_path
  end

  ###
  # Returns the list to use for auto completes for customer names.
  ###
  def auto_complete_for_customer_name
    text = params[:term]
    if !text.blank?
      @customers = current_user.company.customers.order('name').where('name LIKE ? OR name LIKE ?', text + '%', '% ' + text + '%').limit(50)
      render :json=> @customers.collect{|customer| {:value => customer.name, :id=> customer.id} }.to_json
    else
      render :nothing=> true
    end
  end

  def search
    search_criteria = params[:term].strip

    @customers = []
    @users = []
    @tasks = []
    @projects = []
    @resources = []
    @limit = 5
    unless search_criteria.blank?
      if search_criteria.to_i > 0
        @tasks = Task.all_accessed_by(current_user).where(:task_num => search_criteria)
      elsif params[:entity]
        @limit = 100000
        if params[:entity] =~ /user/
          @users = current_user.company.users.where('lower(name) LIKE ?', '%' + search_criteria.downcase + '%').where(:active => true)
        elsif params[:entity] =~ /customer/
          @customers = current_user.company.customers.where('lower(name) LIKE ?', '%' + search_criteria.downcase + '%').where(:active => true)
        elsif params[:entity] =~ /task/
          @tasks = Task.all_accessed_by(current_user).where('lower(tasks.name) LIKE ?', '%' + search_criteria.downcase + '%').where("tasks.status = 0")
        elsif params[:entity] =~ /resource/
          @resources = current_user.company.resources.where('lower(name) like ?', '%' + search_criteria.downcase + '%') if current_user.use_resources?
        elsif params[:entity] =~ /project/
          @projects = current_user.projects.where('lower(name) like ?', '%' + search_criteria.downcase + '%')
        end
      else
        @customers = current_user.company.customers.where('lower(name) LIKE ?', '%' + search_criteria.downcase + '%').where(:active => true)
        @users = current_user.company.users.where('lower(name) LIKE ?', '%' + search_criteria.downcase + '%').where(:active => true)
        @tasks = Task.all_accessed_by(current_user).where('lower(tasks.name) LIKE ?', '%' + search_criteria.downcase + '%').where("tasks.status = 0")
        @resources = current_user.company.resources.where('lower(name) like ?', '%' + search_criteria.downcase + '%') if current_user.use_resources?
        @projects = current_user.projects.where('lower(name) like ?', '%' + search_criteria.downcase + '%')
      end
    end

    html = render_to_string :partial => "customers/search_autocomplete", :locals => {:users => @users, :customers => @customers, :tasks => @tasks, :projects => @projects, :resources => @resources, :limit => @limit }
    render :json=> { :success => true, :html => html }
  end

  private

  def authorize_user_can_create_customers
    deny_access unless current_user.admin? or current_user.create_clients?
  end

  def authorize_user_can_edit_customers
    deny_access unless current_user.admin? or current_user.edit_clients?
  end

  def authorize_user_can_read_customers
    deny_access unless current_user.admin? or current_user.read_clients?
  end

  def deny_access
    flash[:error] = _("Access denied")
    redirect_from_last
  end
end
