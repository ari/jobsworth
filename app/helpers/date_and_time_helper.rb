###
# Helpers for displaying dates and times
###
module DateAndTimeHelper
  def formatted_datetime_for_current_user(datetime)
    datetime.strftime("#{ current_user.date_format } #{ current_user.time_format }") if datetime
  end
end
