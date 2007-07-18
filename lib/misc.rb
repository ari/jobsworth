module Misc

  $CONFIG ||= { :domain => "clockingit.com" }

  # Format minutes => <tt>1w 2d 3h 3m</tt>
  def format_duration(minutes, duration_format, day_duration)
    res = ''
    weeks = days = hours = 0

    if minutes >= 60

      days = minutes / day_duration
      minutes = minutes - (days * day_duration) if days > 0

      weeks = days / 5
      days = days - (weeks * 5) if weeks > 0

      hours = minutes / 60
      minutes = minutes - (hours * 60) if hours > 0

      res += "#{weeks}#{_('w')}#{' ' if duration_format == 0}" if weeks > 0
      res += "#{days}#{_('d')}#{' ' if duration_format == 0}" if days > 0
      res += "#{hours}#{_('h')}#{' ' if duration_format == 0}" if hours > 0
    end
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
      res = format("%d:%02d", ((weeks * day_duration * 5) + (days * day_duration))/60 + hours, minutes)
    end

    res.strip
  end

end
