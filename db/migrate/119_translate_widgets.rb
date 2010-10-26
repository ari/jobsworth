
class TranslateWidgets < ActiveRecord::Migration
  def self.up
    Widget.all.each do |w|

      if ["Top Tasks", "Newest Tasks", "Recent Activities", "Open Tasks", "Projects"].include? w.attributes['name']
        Localization.lang(w.user.locale || 'en_US')
        w.name = _(w.attributes['name'])
        w.save
      end 
      
    end
  end
    
  def self.down
  end
end
