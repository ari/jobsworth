# encoding: UTF-8
###
# Helpers for displaying dates and times
###
module DateAndTimeHelper

  ###
  # Returns a string of the given date time formatted according to
  # the current user's preferences
  ###
  def formatted_datetime_for_current_user(datetime)
    datetime.strftime("#{ current_user.date_format } #{ current_user.time_format }") if datetime
  end

  # Returns a string of the given date formatted according to the
  # current user's preferences
  def formatted_date_for_current_user(date)
    tz.utc_to_local(date.to_time).strftime("#{ current_user.date_format }") if date
  end

  ###
  # Parses the date string at params[key_name] according to the
  # current user's prefs. If no date is found, the current
  # date is returned.
  # The returned data will always be in UTC.
  ###
  def date_from_string(str)
    TimeParser.date_from_string(current_user, str)
  end

end
