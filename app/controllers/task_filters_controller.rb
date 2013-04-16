# encoding: UTF-8
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
    @to_list << [ Customer.model_name.human(count: 2),
                  Customer.where(name_conds("customers.")).limit(limit) ]
    @to_list << [ Project.model_name.human(count: 2),
                  current_user.projects.where(name_conds).limit(limit) ]
    @to_list << [ User.model_name.human(count: 2),
                  company.users.where(name_conds).limit(limit) ]
    @to_list << [ Milestone.model_name.human(count: 2),
                  current_user.milestones.where("milestones.completed_at IS ?", nil).where(name_conds("milestones.")).limit(limit) ]
    @to_list << [ Tag.model_name.human(count: 2),
                  company.tags.where(name_conds).limit(limit) ]
    @to_list << [ t('tasks.resolution'),
                  company.statuses.where(name_conds).limit(limit) ]

    company.properties.each do |property|
      values = property.property_values.where("lower(value) like ?", "#{ @filter }%")
      @to_list << [ property, values ] if values.any?
    end

    @date_columns = []
    [ :due_at, :created_at, :updated_at ].each do |column|
      matches = TimeRange.where(name_conds).limit(limit)
      @date_columns << [ column, matches ]
    end

    @unread_only = @filter.index("unread")

    array = []
    @to_list.each do |name, values|
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
    if params[:replace_filter]
      @filter = current_user.company.task_filters.find(params[:filter_to_replace])
      @filter.select_filter(current_task_filter)
      flash[:success] = "filter #{@filter.name} updated successfully."
    else
      @filter = TaskFilter.new(params[:task_filter])
      @filter.user = current_user
      @filter.copy_from(current_task_filter)
      if !@filter.save
        flash[:error] = @filter.errors.full_messages.join(" ")
      else
        flash[:success] = "filter #{@filter.name} created successfully."
      end
    end

    redirect_using_js_if_needed("/tasks")
  end

  # Select a search filter which causes the search filter partial to be reloaded
  def select
    @filter = current_user.company.task_filters.find(params[:id])

    if @filter.user == current_user or @filter.shared?
      current_task_filter.select_filter(@filter)
    else
      flash[:error] = t('flash.alert.access_denied_to_model', model: TaskFilter.model_name.human)
    end
    if request.xhr?
      render :partial => "search_filter_keys"
    else
      redirect_to '/tasks'
    end
  end

  def update_current_filter
    # sets the current filter from the given params
    current_task_filter.update_filter(params[:task_filter])
    current_task_filter.store_for(current_user)

    if request.xhr?
      render :partial => 'search_filter_keys'
    else
      redirect_to(params[:redirect_action] || "/tasks")
    end
  end

  def destroy
    filter = current_user.company.task_filters.find(params[:id])

    if (filter.user == current_user) ||
        (filter.shared? and current_user.admin?)
      filter.destroy
      flash[:success] = t('flash.notice.model_deleted', model: TaskFilter.model_name.human)
    else
      flash[:error] = t('flash.alert.access_denied_to_model', model: TaskFilter.model_name.human)
    end

    if request.xhr?
      render :partial => "/task_filters/list"
    else
      redirect_to "/tasks"
    end
  end

  def toggle_status
    @filter = TaskFilter.find(params[:id])
    if @filter.user == current_user || @filter.company == current_user.company
      if @filter.show?(current_user)
        @filter.task_filter_users.where(:user_id => current_user.id).first.destroy
      else
        @filter.task_filter_users.create(:user_id => current_user.id)
      end
    end
    render :partial => "/task_filters/list"
  end

  private

  def name_conds(prefix = nil)
    name_conds = [ "lower(#{ prefix }name) like ?", "#{ @filter }%" ]
  end
end
