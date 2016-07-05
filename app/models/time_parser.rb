# encoding: UTF-8
class TimeParser

  # def self.format_duration(minutes, spent = false)
  #   weeks, days, hours, minutes = minutes / 10080, (minutes / 1440) % 7, (minutes / 60) % 24, minutes % 60

  # Format is 30h50m
  # Parse minutes => <tt>30h50m</tt>
  def self.format_duration(minutes, spent = false)
    if minutes.present?
      hours, minutes = (minutes / 60) % 24, minutes % 60
      minutes < 10 ? "#{hours}h0#{minutes}m" : "#{hours}h#{minutes}m"
    else
      "0:00"
    end
  end

  ###
  # Parses the date string according to the
  # current user's prefs. If no date is found, the current
  # date is returned.
  # The returned data will always be in UTC.
  ###
  def self.date_from_string(user, str)
    res = Time.now.utc

    begin
      format = "#{user.date_format} #{user.time_format}"
      res = DateTime.strptime(str, format).ago(user.tz.current_period.utc_total_offset)
    rescue ArgumentError
      # just fall back to default if error
    end

    return res
  end

  # Parse <tt>30h50m</tt> => minutes
  def self.parse_time(input)
    return 0 unless input.present?
    total = 0
    hours = input.split('h')[0].to_i
    minutes = input.split('h')[1].chomp('m').to_i
    total = hours * 60 + minutes
  end

end
