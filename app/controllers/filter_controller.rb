class FilterController < ApplicationController
  layout nil

  def index
    filter = params[:filter]
    return if filter.blank?

    filter = filter.downcase
    name_conds = [ "lower(name) like ?", "#{ filter }%" ]
    @customers = current_user.company.customers.all(:conditions => name_conds)
    @projects = current_user.company.projects.all(:conditions => name_conds)
    @users = current_user.company.users.all(:conditions => name_conds)
    @statuses = Task.status_types.select { |type| _(type).downcase.index(filter) == 0 }

    @properties = []
    current_user.company.properties.each do |property|
      values = property.property_values.all(:conditions => [ "value like ?", "#{ filter }%" ])
      @properties << [ property, values ] if values.any?
    end
  end
end
