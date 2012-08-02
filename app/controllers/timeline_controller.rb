# encoding: UTF-8
# Filter WorkLogs in different ways, with pagination

class TimelineController < ApplicationController
  def index
    params[:filter_date] ||= 1
    params[:filter_project] ||= 0
    params[:filter_status] ||= -1
    @logs = EventLog.event_logs_for_timeline(current_user, params)

    if request.xhr?
      render :template => "timeline/index.json"
    else
      render :index
    end
  end
end
