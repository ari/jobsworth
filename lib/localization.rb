module Localization

  @@l10s = { :default => {} }
  @@lang = :default

  def self.locales
    [['English', 'en_US'], ['Español', 'es_ES'], ['Deutsch', 'de_DE'], ['Nederlands', 'nl_NL'], ['Norsk', 'no_NO']]
  end

  def self._(string_to_localize, *args)
    translated =
      @@l10s[@@lang][string_to_localize] || string_to_localize
    return translated.call(*args).to_s if translated.is_a? Proc
    translated =
      translated[args[0]>1 ? 1 : 0] if translated.is_a?(Array)
    sprintf translated, *args
  end

  def self.define(lang = :default)
    @@l10s[lang] ||= {}
    yield @@l10s[lang]
  end

  def self.load
    Dir.glob("#{RAILS_ROOT}/lang/*.rb"){ |t| require t }
    Dir.glob("#{RAILS_ROOT}/lang/custom/*.rb"){ |t| require t }
  end

  def self.lang(locale)
    @@lang = locale
    Date.translate_strings
  end

end

class Date
  def self.translate_strings
    Date::MONTHNAMES.replace([nil, _('January'), _('February'), _('March'), _('April'), _('May'), _('June'), _('July'), _('August'), _('September'), _('October'), _('November'). _('December')])
    Date::DAYNAMES.replace([_('Sunday'), _('Monday'), _('Tuesday'), _('Wednesday'), _('Thursday'), _('Friday'), _('Saturday')])
    Date::ABBR_MONTHNAMES.replace([nil, _('Jan'), _('Feb'), _('Mar'), _('Apr'), _('May'), _('Jun'), _('Jul'), _('Aug'), _('Sep'), _('Oct'), _('Nov'). _('Dec')])
    Date::ABBR_DAYNAMES.replace([_('Sun'), _('Mon'), _('Tue'), _('Wed'), _('Thu'), _('Fri'), _('Sat')])
  end
end


class Time
  alias :strftime_nolocale :strftime

  def strftime(format)
    format = format.dup
    format.gsub!(/%a/, Date::ABBR_DAYNAMES[self.wday])
    format.gsub!(/%A/, Date::DAYNAMES[self.wday])
    format.gsub!(/%b/, Date::ABBR_MONTHNAMES[self.mon])
    format.gsub!(/%B/, Date::MONTHNAMES[self.mon])
    self.strftime_nolocale(format)
  end
end


class Object
  def _(*args); Localization._(*args); end
end

# Generates a best-estimate l10n file from all views by
# collecting calls to _() -- note: use the generated file only
# as a start (this method is only guesstimating)
def self.generate_l10n_file
  "Localization.define('en_US') do |l|\n" <<
  Dir.glob("#{RAILS_ROOT}/app/views/**/*.rhtml").collect do |f|
    ["# #{f}"] << File.read(f).scan(/<%.*[^\w]_\s*[\"\'](.*?)[\"\']/)
  end.uniq.flatten.collect do |g|
    g.starts_with?('#') ? "\n  #{g}" : "  l.store '#{g}', '#{g}'"
  end.uniq.join("\n") << "\nend"
end

module ActionView::Helpers::DateHelper
  def distance_of_time_in_words(from_time, to_time = 0, include_seconds = false)
    from_time = from_time.to_time if from_time.respond_to?(:to_time)
    to_time = to_time.to_time if to_time.respond_to?(:to_time)
    distance_in_minutes = (((to_time - from_time).abs)/60).round
    distance_in_seconds = ((to_time - from_time).abs).round

    case distance_in_minutes
    when 0..1
      return (distance_in_minutes==0) ? _('less than a minute') : _('%d minute', 1) unless include_seconds
      case distance_in_seconds
      when 0..5   then _('less than %d seconds', 5)
      when 6..10  then _('less than %d seconds', 10)
      when 11..20 then _('less than %d seconds', 20)
      when 21..40 then _('half a minute')
      when 41..59 then _('less than a minute')
      else             _('%d minute',1)
      end

    when 2..45      then _("%d minute", distance_in_minutes)
    when 46..90     then _('about %d hour', 1)
    when 90..1440   then _("about %d hour", (distance_in_minutes.to_f / 60.0).round)
    when 1441..2880 then _('%d day', 1)
    else                 _('%d day', (distance_in_minutes / 1440).round)
    end
  end
end
