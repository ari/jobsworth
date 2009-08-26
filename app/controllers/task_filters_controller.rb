class TaskFiltersController < ApplicationController
  layout nil, :except => "new"
  layout "popup", :only => "new"

  def search
    @filter = params[:filter]
    return if @filter.blank?

    @filter = @filter.downcase
    name_conds = [ "lower(name) like ?", "#{ @filter }%" ]
    limit = 10

    @to_list = []

    c = current_user.company

    customers = c.customers.all(:conditions => name_conds, :limit => limit)
    @to_list << [ _("Clients"), customers ]

    projects = c.projects.all(:conditions => name_conds, :limit => limit)
    @to_list << [ _("Projects"), projects ]

    users = c.users.all(:conditions => name_conds, :limit => limit)
    @to_list << [ _("Users"), users ]

    milestones = c.milestones.all(:conditions => name_conds, :limit => limit)
    @to_list << [ _("Milestones"), milestones ]

    tags = c.tags.all(:conditions => name_conds, :limit => limit)
    @to_list << [ _("Tags"), tags ]

    @to_list << [ _("Status"), c.statuses.all(:conditions => name_conds, :limit => limit) ]

    current_user.company.properties.each do |property|
      values = property.property_values.all(:conditions => [ "value like ?", "#{ @filter }%" ])
      @to_list << [ property, values ] if values.any?
    end
  end

  def new
    @filter = TaskFilter.new(:user => current_user)
  end

  def create
    @filter = TaskFilter.new(params[:task_filter])
    @filter.user = current_user
    current_task_filter.qualifiers.each { |q| @filter.qualifiers << q.clone }
    current_task_filter.keywords.each do |kw| 
      # N.B Shouldn't have to pass in all these values, but it 
      # doesn't work when we don't, so...
      @filter.keywords.build(:task_filter => @filter,
                             :company => current_user.company, 
                             :word => kw.word)
    end

    if !@filter.save
      flash[:notice] = _"Filter couldn't be saved. A name is required"
    end
    
    redirect_using_js_if_needed("/tasks/list")
  end

  def select
    @filter = current_user.company.task_filters.find(params[:id])

    if @filter.user == current_user or @filter.shared?
      target_filter = current_task_filter
      @filter.qualifiers.each { |q| target_filter.qualifiers << q.clone }
      @filter.keywords.each do |kw| 
        # N.B Shouldn't have to pass in all these values, but it 
        # doesn't work when we don't, so...
        target_filter.keywords.build(:task_filter => target_filter,
                                     :company => current_user.company, 
                                     :word => kw.word)
      end
    else
      flash[:notice] = _"You don't have access to that task filter"
    end

    redirect_to "/tasks/list"
  end

  def update_current_filter
    # sets the current filter from the given params
    filter = current_task_filter
    filter.keywords.clear
    filter.qualifiers.clear
    filter.attributes = params[:task_filter]
    filter.save

    redirect_to(params[:redirect_action] || "/tasks/list")
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

  def destroy
    filter = current_user.company.task_filters.find(params[:id])

    if (filter.user == current_user) or 
        (filter.shared? and current_user.admin?)
      filter.destroy
      flash[:notice] = _("Task filter deleted")
    else
      flash[:notice] = _("You don't have access to delete that task filter")
    end

    redirect_to "/tasks/list"
  end
end
