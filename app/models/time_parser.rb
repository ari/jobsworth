# encoding: UTF-8
class TimeParser

  # Format minutes => <tt>3h 3m</tt>
  def self.format_duration(minutes, spent = false)
    hours, minutes = minutes / 60, minutes % 60

    t_key = if spent
      if hours.zero?
        "shared.duration_in_minutes_spent"
      elsif minutes.zero?
        "shared.duration_in_hours_spent"
      else
        "shared.duration_in_hours_and_minutes_spent"
      end
    else
      if hours.zero?
        "shared.duration_in_minutes"
      elsif minutes.zero?
        "shared.duration_in_hours"
      else
        "shared.duration_in_hours_and_minutes"
      end
    end
    I18n.t(t_key, :hours => hours, :minutes => minutes)
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

  # Parse <tt>3h 4m</tt> => minutes
  def self.parse_time(input)
    return 0 if input.nil?
    total = 0
    input.downcase.gsub(/([hm])/,'\1 ').split(' ').each do |e|
      part = /(\d+)(\w+)/.match(e)
      if part && part.size == 3
        case  part[2]
        when 'h' then total += e.to_i * 60
        when 'm' then total += e.to_i
        end
      end
    end

    if total == 0 && input.to_i > 0
      total = input.to_i
    end

    total
  end
  
end
