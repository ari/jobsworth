# encoding: UTF-8
class TimeParser

  # Format minutes => <tt>1w 2d 3h 3m</tt>
  def self.format_duration(minutes, duration_format, day_duration, days_per_week = 5)
    res = ''
    weeks = days = hours = 0

    day_duration ||= 480
    minutes ||= 0

    if minutes >= 60

      days = minutes / day_duration
      minutes = minutes - (days * day_duration) if days > 0

      weeks = days / days_per_week
      days = days - (weeks * days_per_week) if weeks > 0

      hours = minutes / 60
      minutes = minutes - (hours * 60) if hours > 0

      weeks = weeks.round(2) if [Float, BigDecimal].include?(weeks.class)
      days = days.round(2) if [Float, BigDecimal].include?(days.class)
      hours = hours.round(2) if [Float, BigDecimal].include?(hours.class)

      res += "#{weeks}#{_('w')}#{' ' if duration_format == 0}" if weeks > 0
      res += "#{days}#{_('d')}#{' ' if duration_format == 0}" if days > 0
      res += "#{hours}#{_('h')}#{' ' if duration_format == 0}" if hours > 0
    end
    minutes = minutes.round(2) if [Float, BigDecimal].include?(minutes.class)
    res += "#{minutes}#{_('m')}" if minutes > 0 || res == ''

    if( duration_format == 2 )
      res = if weeks > 0
              format("%d:%d:%d:%02d", weeks, days, hours, minutes)
            elsif days > 0
              format("%d:%d:%02d", days, hours, minutes)
            else
              format("%d:%02d", hours, minutes)
            end
    elsif( duration_format == 3 )
      res = format("%d:%02d", ((weeks * day_duration * days_per_week) + (days * day_duration))/60 + hours, minutes)
    end

    res.strip
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

  # Parse <tt>1w 2d 3h 4m</tt> or <tt>1:2:3:4</tt> => minutes or seconds
  def self.parse_time(user, input, minutes = false)
    total = 0
    unless input.nil?
      miss = false
      reg = Regexp.new("(#{_('[wdhm]')})")
      input.downcase.gsub(reg,'\1 ').split(' ').each do |e|
        part = /(\d+)(\w+)/.match(e)
        if part && part.size == 3
          case  part[2]
          when _('w') then total += e.to_i * user.workday_duration * user.days_per_week
          when _('d') then total += e.to_i * user.workday_duration
          when _('h') then total += e.to_i * 60
          when _('m') then total += e.to_i
          else 
            miss = true
          end
        end
      end

      # Fallback to default english parsing
      if miss
        eng_total = 0
        reg = Regexp.new("([wdhm])")
        input.downcase.gsub(reg,'\1 ').split(' ').each do |e|
          part = /(\d+)(\w+)/.match(e)
          if part && part.size == 3
            case  part[2]
            when 'w' then eng_total += e.to_i * user.workday_duration * user.days_per_week
            when 'd' then eng_total += e.to_i * user.workday_duration
            when 'h' then eng_total += e.to_i * 60
            when 'm' then eng_total += e.to_i
            end
          end
        end
        
        if eng_total > total
          total = eng_total
        end
        
      end
      
      if total == 0
        times = input.split(':')
        while time = times.shift
          case times.size
          when 0 then total += time.to_i
          when 1 then total += time.to_i * 60
          when 2 then total += time.to_i * user.workday_duration
          when 3 then total += time.to_i * user.workday_duration * user.days_per_week
          end
        end
      end

      if total == 0 && input.to_i > 0
        total = input.to_i
      end

      total = total * 60 unless minutes
      
    end
    total
  end
  
end
