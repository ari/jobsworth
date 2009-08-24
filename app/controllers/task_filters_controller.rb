class TaskFiltersController < ApplicationController
  layout nil, :except => "new"
  layout "popup", :only => "new"

  def search
    filter = params[:filter]
    return if filter.blank?

    filter = filter.downcase
    name_conds = [ "lower(name) like ?", "#{ filter }%" ]
    limit = 10

    @to_list = []

    @customers = current_user.company.customers.all(:conditions => name_conds, :limit => limit)
    @to_list << [ _("Clients"), @customers ]

    @projects = current_user.company.projects.all(:conditions => name_conds, :limit => limit)
    @to_list << [ _("Projects"), @projects ]

    @users = current_user.company.users.all(:conditions => name_conds, :limit => limit)
    @to_list << [ _("Users"), @users ]

    @milestones = current_user.company.milestones.all(:conditions => name_conds, :limit => limit)
    @to_list << [ _("Milestones"), @milestones ]

    @tags = current_user.company.tags.all(:conditions => name_conds, :limit => limit)
    @to_list << [ _("Tags"), @tags ]

    current_user.company.properties.each do |property|
      values = property.property_values.all(:conditions => [ "value like ?", "#{ filter }%" ])
      @to_list << [ property, values ] if values.any?
    end

    # TODO: need to handle these somehow
    @statuses = Task.status_types.select { |type| _(type).downcase.index(filter) == 0 }
  end

  def new
    @filter = TaskFilter.new(:user => current_user)
  end

  def create
    @filter = TaskFilter.new(params[:task_filter])
    @filter.qualifiers = current_task_filter.qualifiers.clone
    @filter.user = current_user

    if @filter.save
      session[:task_filter] = @filter
    else
      flash[:notice] = _"Filter couldn't be saved. A name is required"
    end
    
    redirect_using_js_if_needed("/tasks/list")
  end

  def select
    @filter = current_user.company.task_filters.find(params[:id])
    
    if @filter.user == current_user or @filter.shared?
      session[:task_filter] = @filter
    else
      flash[:notice] = _"You don't have access to that task filter"
    end

    redirect_to "/tasks/list"
  end

  def update_current_filter
    # sets the current filter from the given params
    filter = TaskFilter.new(:user => current_user)
    filter.attributes = params[:task_filter]

    session[:task_filter] = filter
    redirect_to(params[:redirect_action])
  end

  def set_single_task_filter
    name = "filter_#{ params[:name] }".to_sym
    value = params[:value]

    session[name] = value
    # if we are setting a new filter, we can't still be in a view
    # so clear this
    session[:view] = nil

    render :text => ""
  end
end
