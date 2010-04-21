# Filter WorkLogs in different ways, with pagination
class TimelineController < ApplicationController

  def list
    if current_user.admin == 0
      flash['notice'] = _("Sorry, only admins can use timeline in next few days.")
      redirect_to '/'
      return false
    end

    @filter_params = {}

    [:filter_user, :filter_status, :filter_project, :filter_date].each do |fp|
      @filter_params[fp] = params[fp] unless params[fp].blank?
    end

    @logs, @work_logs= EventLog.event_logs_for_timeline(current_user, params)
  end
end
