module Misc

  defaults = { :domain => "getjobsworth.org", :replyto => "admin", :from => "admin", :prefix => "[Jobsworth]" }

  $CONFIG ||= { }
  defaults.keys.each do |k|
    $CONFIG[k] ||= defaults[k]
  end

  $CONFIG[:email_domain] = $CONFIG[:domain].gsub(/:\d+/, '')

  # Format minutes => <tt>1w 2d 3h 3m</tt>
  def format_duration(minutes, duration_format, day_duration, days_per_week = 5)
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

  # Returns an array of languages codes that the client accepts sorted after
  # priority. Returns an empty array if the HTTP_ACCEPT_LANGUAGE header is
  # not present.
  def accept_locales
    return [] unless request.env.include? 'HTTP_ACCEPT_LANGUAGE'
    languages = request.env['HTTP_ACCEPT_LANGUAGE'].split(',').map do |al|
      al.gsub!(/-/, '_')
      al = al.split(';')
      (al.size == 1) ? [al.first, 1.0] : [al.first, al.last.split('=').last.to_f]
    end
    languages.reject {|x| x.last == 0 }.sort {|x,y| -(x.last <=> y.last) }.map {|x| x.first }
  end
end
