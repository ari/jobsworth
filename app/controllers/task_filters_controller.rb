class TaskFiltersController < ApplicationController

  def search
    @filter = params[:term]
    if @filter.blank?
      render :nothing=>true
      return
    end

    @filter = @filter.downcase
    limit = 10
    company = current_user.company

    @to_list = []
    @to_list << [ _("Clients"), Customer.all(:conditions => name_conds("customers."), :limit => limit) ]
    @to_list << [ _("Projects"), current_user.all_projects.all(:conditions => name_conds, :limit => limit) ]
    @to_list << [ _("Users"), company.users.all(:conditions => name_conds, :limit => limit) ]
    @to_list << [ _("Milestones"), current_user.milestones(:conditions => name_conds("milestones."), :limit => limit) ]
    @to_list << [ _("Tags"), company.tags.all(:conditions => name_conds, :limit => limit) ]
    @to_list << [ _("Resolution"), company.statuses.all(:conditions => name_conds, :limit => limit) ]

    company.properties.each do |property|
      values = property.property_values.all(:conditions => [ "lower(value) like ?", "#{ @filter }%" ])
      @to_list << [ property, values ] if values.any?
    end

    @date_columns = []
    [ :due_at, :created_at, :updated_at ].each do |column|
      matches = TimeRange.all(:conditions => name_conds, :limit => limit)
      @date_columns << [ column, matches ]
    end

    @unread_only = @filter.index("unread")

    array = []
    (@to_list || []).each do |name, values|
      if values and values.any?
       values.each do |v|
          array<< {:id =>  "task_filter[qualifiers_attributes][][qualifiable_id]",
                   :idval => v.id,
                   :type=> "task_filter[qualifiers_attributes][][qualifiable_type]", :typeval => v.class.name,
                   :reversed => "task_filter[qualifiers_attributes][][reversed]",
                   :reversedval=>false,
                   :value => v.to_s,
                   :category => name.to_s}
        end
      end
    end

    (@date_columns || []).each do |column, matches|
          next if matches.empty?

            matches.each do |m|
              array << {:id => "task_filter[qualifiers_attributes][][qualifiable_id]",
                        :idval => m.id,
                        :type => "task_filter[qualifiers_attributes][][qualifiable_type]",
                        :typeval => m.class.name,
                        :col => "task_filter[qualifiers_attributes][][qualifiable_column]",
                        :colval => column.to_s,
                        :reversed => "task_filter[qualifiers_attributes][][reversed]",
                        :reversedval=>false,
                        :value => m.name.to_s,
                        :category => column.to_s.gsub("at", "").humanize}
          end
    end

    if !@filter.blank?

          array << {:id => "task_filter[keywords_attributes][][word]",
                    :idval=> @filter,
                    :value => @filter,
                    :reversed => "task_filter[keywords_attributes][][reversed]",
                    :reversedval=>false,
                    :category => "Keyword"}
    end

    if @unread_only

         array << {:id => "task_filter[unread_only]",
                   :idval => true,
                   :value => "My unread tasks only",
                   :category =>"Read Status"}
    end

    render :json => array.to_json
  end

  def new
    @filter = TaskFilter.new(:user => current_user)
    render :layout => false
  end

  def create
    @filter = TaskFilter.new(params[:task_filter])
    @filter.user = current_user
    @filter.copy_from(current_task_filter)

    if !@filter.save
      flash[:notice] = _"Filter couldn't be saved. A name is required"
    end

    redirect_using_js_if_needed("/tasks/list")
  end

  # Select a search filter which causes the search filter partial to be reloaded
  def select
    @filter = current_user.company.task_filters.find(params[:id])

    if @filter.user == current_user or @filter.shared?
      target_filter = current_task_filter
      target_filter.qualifiers.clear
      target_filter.keywords.clear
      target_filter.copy_from(@filter)
      target_filter.save!
    else
      flash[:notice] = _"You don't have access to that task filter"
    end
    if request.xhr?
      render :partial => "search_filter_keys"
    else
      redirect_to '/tasks/list'
    end
  end

  def update_current_filter
    # sets the current filter from the given params
    filter = current_task_filter
    filter.keywords.clear
    filter.qualifiers.clear
    filter.unread_only = false

    filter.attributes = params[:task_filter]
    filter.save
    filter.store_for(current_user)
    if request.xhr?
      render :partial => 'search_filter_keys'
    else
      redirect_to(params[:redirect_action] || "/tasks/list")
    end
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

  def recent
    @filters = TaskFilter.recent_for(current_user)
    render :layout =>false
  end
  private

  def name_conds(prefix = nil)
    name_conds = [ "lower(#{ prefix }name) like ?", "#{ @filter }%" ]
  end
end
