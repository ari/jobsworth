class FilterController < ApplicationController
  layout nil

  def index
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

  def update
    # sets the current filter from the given params
    filter = TaskFilter.new(:user => current_user)
    debugger
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
