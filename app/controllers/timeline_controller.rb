# encoding: UTF-8
# Filter WorkLogs in different ways, with pagination

class TimelineController < ApplicationController
  def index
    @filter_params = {}
    [:filter_user, :filter_status, :filter_project, :filter_date, :filter_task].each do |fp|
      @filter_params[fp] = params[fp] unless params[fp].blank?
    end

    @logs = EventLog.event_logs_for_timeline(current_user, params)
  end
end
