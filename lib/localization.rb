# coding: utf-8

module Localization

  @@l10s = { :default => {} }
  @@lang = :default

  def self.locales
    [['English', 'en_US'], ['Česky', 'cz_CZ'], ['简体中文', 'zh_ZH'], ['Dansk', 'dk_DK'], ['Deutsch', 'de_DE'], ['Euskara', 'eu_ES'], ['Español', 'es_ES'], ['Français', 'fr_FR'], ['עברית', 'il_IL'], ['Italiano', 'it_IT'], ['한국어', 'ko_KO'], ['Lietuvių kalba','lt_LT'], ['Magyar', 'hu_HU'], ['Nederlands', 'nl_NL'], ['Norsk', 'no_NO'], ['Polski', 'pl_PL'], ['Português Brazilian', 'pt_BR'], ['Suomi', 'fi_FI'], ['Svensk', 'sv_SV']]
  end

  def self._(string_to_localize, *args)
    translated = @@l10s[@@lang][string_to_localize] 
    if translated.nil?
      l = nil
      l = Locale.where("locales.locale = ? AND locales.key = ?", @@lang, string_to_localize).first rescue nil
      if @@lang != :default && l.nil?
        l = Locale.new
        l.locale = @@lang
        l.key = string_to_localize.strip
        l.singular = string_to_localize.strip
        l.plural = string_to_localize.strip if string_to_localize.include?('%d')
        l.save if @@lang != 'en_US' || (@@lang == 'en_US' && l.plural != nil) rescue nil

        translated = string_to_localize.strip
      elsif @@lang != :default
        translated = [l.singular, l.plural] if l.plural
        translated ||= l.singular
      else 
        translated = string_to_localize
      end 
    end 
    @@l10s[@@lang][string_to_localize] = translated
    return translated.call(*args).to_s if translated.is_a? Proc
    translated =
      translated[args[0]>1 ? 1 : 0] if translated.is_a?(Array)
    sprintf translated, *args rescue sprintf string_to_localize, *args 
  end

  def self.define(lang = :default)
    @@l10s[lang] ||= {}
    yield @@l10s[lang]
  end

  def self.load
    Dir.glob(Rails.root.join("lang", "*.rb")){ |t| require t }
    Dir.glob(Rails.root.join("lang", "custom", "*.rb")){ |t| require t }
  end

  def self.lang(locale = nil)
    @@lang = locale if locale
    @@l10s[@@lang] ||= { }
    @@lang
  end
  
  def self.l10s
    @@l10s
  end 
  
end

class Date
  def strftime_localized(format)
    format = format.dup
    format.gsub!(/%a/, _(Date::ABBR_DAYNAMES[self.wday]))
    format.gsub!(/%A/, _(Date::DAYNAMES[self.wday]))
    format.gsub!(/%b/, _(Date::ABBR_MONTHNAMES[self.mon]))
    format.gsub!(/%B/, _(Date::MONTHNAMES[self.mon]))
    self.strftime(format)
  end

end


class Time
  def strftime_localized(format)
    format = format.dup
    format.gsub!(/%a/, _(Date::ABBR_DAYNAMES[self.wday]))
    format.gsub!(/%A/, _(Date::DAYNAMES[self.wday]))
    format.gsub!(/%b/, _(Date::ABBR_MONTHNAMES[self.mon]))
    format.gsub!(/%B/, _(Date::MONTHNAMES[self.mon]))
    self.strftime(format)
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
  Dir.glob("#{Rails.root}/app/views/**/*.rhtml").collect do |f|
    ["# #{f}"] << File.read(f).scan(/<%.*[^\w]_\s*[\"\'](.*?)[\"\']/)
  end.uniq.flatten.collect do |g|
    g.starts_with?('#') ? "\n  #{g}" : "  l.store '#{g}', '#{g}'"
  end.uniq.join("\n") << "\nend"
end
