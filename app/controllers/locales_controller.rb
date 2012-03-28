# encoding: UTF-8
class LocalesController < ApplicationController

  def index
    redirect_to :action => 'list'
  end
  
  def list
    @keys = Locale.where("locales.locale = ?", current_user.locale).order("locales.same = 1, locales.key = locales.singular desc, length(locales.key),locales.key")
    unless current_user.locale != 'en_US' || current_user.admin.to_i == 10
      flash[:alert] = 'Please select your preferred language from your <a href="/users/edit_preferences">Preferences</a> page.'.html_safe
      redirect_to :controller => 'activities', :action => 'index'
    end 
  end

  def update
    modified = false
    count = 0
    params[:singular][current_user.locale].keys.each do |i|
      modified = false
      l = Locale.where("locales.locale = ?", current_user.locale).find(i)
      
      #Count %'s in key, make sure they're the same in translation
      args = l.key.split("%").size
      
      singular = params[:singular][current_user.locale][i].strip 
      plural = params[:plural][current_user.locale][i].strip if l.plural && params[:plural] && params[:plural][current_user.locale][i]
      same = 0
      same = params[:same][current_user.locale][i] if params[:same] && params[:same][current_user.locale][i] 
      
      if l.singular != singular && singular.length > 0 && singular.split("%").size <= args
        logger.info("updating[#{current_user.locale}][#{l.singular}] => [#{params[:singular][current_user.locale][i].strip}]")
        l.singular = params[:singular][current_user.locale][i].strip 
        modified = true
      end 
      if l.plural && plural && l.plural != plural && plural.strip.length > 0 && plural.split("%").size <= args
        l.plural = params[:plural][current_user.locale][i].strip
        modified = true
      end 
      
      if l.same != (same.to_i == 1)
        modified = true
        l.same = (same.to_i == 1)
      end
      
      if modified
        l.user = current_user
        l.save
        count += 1
      end 
    end
    if count > 0
      flash[:info] = _('%d translations updated.', count)
    end
    redirect_to :action => 'list'
  end
end
