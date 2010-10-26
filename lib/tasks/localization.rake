require 'date'
require "#{Rails.root}/lib/localization"

namespace :locale do

  desc "Restore translations into database"
  task :restore => [:environment] do
    Localization.load
    Localization.locales.each do |locale|
      l = locale[1]
      
      (Localization.l10s[l] || { }).keys.each do |k|
        v = Localization.l10s[l][k]
        n = Locale.where("locales.locale = ? AND locales.key = ?", locale[1], k).first || Locale.new
        n.locale = locale[1]
        n.key = k
        if v.is_a? Array
          n.singular = v[0]
          n.plural = v[1]
        else 
          n.singular = v
        end
        n.save
      end
    end
  end 

  desc "Dump translations from database"
  task :dump => [:environment] do
    Localization.locales.each do |locale|
      l = locale[1]

      File.open("lang/#{l}.rb", "w") do |f|
        f.puts "Localization.define('#{l}') do |l|"

        Locale.where("locale = ?", l).order('length(locales.key), locales.key').each do |k|
          f.print "  l.store \"#{k.key.gsub(/\\/, "\\\\\\").gsub(/"/, "\\\"")}\", "
          if k.plural
            f.print "[\"#{k.singular.gsub(/\\/, "\\\\\\").gsub(/"/, "\\\"")}\", \"#{k.plural.gsub(/\\/, "\\\\\\").gsub(/"/, "\\\"")}\"]"
          else 
            f.print "\"#{k.singular.gsub(/\\/, "\\\\\\").gsub(/"/, "\\\"")}\""
          end
          
          f.print " # #{k.user.name}" if k.user rescue nil
          f.puts
          
        end 

        f.puts "end"
        
      end 
    end
  end 
  
  
end 

