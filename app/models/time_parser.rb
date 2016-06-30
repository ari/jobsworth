# encoding: UTF-8
class TimeParser

  # Format minutes => <tt>3h 3m</tt>
  def self.format_duration(minutes, spent = false)
    weeks, days, hours, minutes = minutes / 10080, (minutes / 1440) % 7, (minutes / 60) % 24, minutes % 60

    t_key = if spent
              if !weeks.zero? && !days.zero? && !hours.zero? && !minutes.zero?
                'shared.duration_in_weeks_and_days_and_hours_and_minutes_spent'
              elsif !weeks.zero? && !days.zero? && !hours.zero?
                'shared.duration_in_weeks_and_days_and_hours_spent'
              elsif !weeks.zero? && !days.zero?
                'shared.duration_in_weeks_and_days_spent'
              elsif !weeks.zero?
                'shared.duration_in_weeks_spent'
              elsif !days.zero? && !hours.zero? && !minutes.zero?
                'shared.duration_in_days_and_hours_and_minutes_spent'
              elsif !days.zero? && !hours.zero?
                'shared.duration_in_days_and_hours_spent'
              elsif !days.zero?
                'shared.duration_in_days_spent'
              elsif !hours.zero? && !minutes.zero?
                'shared.duration_in_hours_and_minutes_spent'
              elsif !hours.zero?
                'shared.duration_in_hours_spent'
              else
                'shared.duration_in_minutes_spent'
              end
            else
              if !weeks.zero? && !days.zero? && !hours.zero? && !minutes.zero?
                'shared.duration_in_weeks_and_days_and_hours_and_minutes'
              elsif !weeks.zero? && !days.zero? && !hours.zero?
                'shared.duration_in_weeks_and_days_and_hours'
              elsif !weeks.zero? && !days.zero?
                'shared.duration_in_weeks_and_days'
              elsif !weeks.zero?
                'shared.duration_in_weeks'
              elsif !days.zero? && !hours.zero? && !minutes.zero?
                'shared.duration_in_days_and_hours_and_minutes'
              elsif !days.zero? && !hours.zero?
                'shared.duration_in_days_and_hours'
              elsif !days.zero?
                'shared.duration_in_days'
              elsif !hours.zero? && !minutes.zero?
                'shared.duration_in_hours_and_minutes'
              elsif !hours.zero?
                'shared.duration_in_hours'
              else
                'shared.duration_in_minutes'
              end
            end
    I18n.t(t_key, :weeks => weeks.abs, :days => days.abs, :hours => hours.abs, :minutes => minutes.abs)
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
    input.downcase.gsub(/([hm])/, '\1 ').split(' ').each do |e|
      part = /(\d+)(\w+)/.match(e)
      if part && part.size == 3
        case part[2]
          when 'h' then
            total += e.to_i * 60
          when 'm' then
            total += e.to_i
        end
      end
    end

    if total == 0 && input.to_i > 0
      total = input.to_i
    end

    total
  end

end
