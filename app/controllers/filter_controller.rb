class FilterController < ApplicationController
  layout nil

  def index
    filter = params[:filter]
    return if filter.blank?

    filter = filter.downcase
    name_conds = [ "lower(name) like ?", "#{ filter }%" ]
    limit = 10

    @customers = current_user.company.customers.all(:conditions => name_conds, :limit => limit)
    @projects = current_user.company.projects.all(:conditions => name_conds, :limit => limit)
    @users = current_user.company.users.all(:conditions => name_conds, :limit => limit)
    @statuses = Task.status_types.select { |type| _(type).downcase.index(filter) == 0 }
    @milestones = current_user.company.milestones.all(:conditions => name_conds, :limit => limit)

    @properties = []
    current_user.company.properties.each do |property|
      values = property.property_values.all(:conditions => [ "value like ?", "#{ filter }%" ])
      @properties << [ property, values ] if values.any?
    end
  end
end
