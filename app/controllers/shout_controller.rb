class ShoutController < ApplicationController

#  cache_sweeper :shout_sweeper, :only => :add_ajax

  def list
    @rooms = ShoutChannel.find(:all, :conditions => ["(company_id IS NULL OR company_id = ?) AND (project_id IS NULL OR project_id IN (#{current_project_ids}))", session[:user].company_id],
                               :order => "company_id, project_id")
  end

  def room
    @room = ShoutChannel.find(:first, :conditions => ["id = ? AND (company_id IS NULL OR company_id = ?) AND (project_id IS NULL OR project_id IN (#{current_project_ids}))", params[:id], session[:user].company_id ])
    unless @room
      redirect_to :action => 'list'
    end
  end

  def leave

  end

  def new_ajax
    @channel = ShoutChannel.new
    render :update do |page|
      page.replace_html 'channel-add-container', :partial => 'add_channel'
      page.show('channel-add-container')
      page.visual_effect(:highlight, "channel-add-container", :duration => 0.5)
    end
  end

  def create_ajax
    @channel = ShoutChannel.new(params[:channel])
    @channel.company = session[:user].company
    if @channel.save
      render :update do |page|
        page.insert_html :top, "channel-list", :partial => 'channel', :locals => { :room => @channel }
        page.visual_effect(:highlight, "channel_#{@channel.id}", :duration => 1.5)
        page['channel-add-container'].hide
      end

    else
      render :update do |page|
        page.visual_effect(:highlight, "channel-add-container", :duration => 0.5, :startcolor => "'#ff9999'")
      end
    end
  end

  def chat_ajax
    room = ShoutChannel.find(:first, :conditions => ["id = ? AND (company_id IS NULL OR company_id = ?) AND (project_id IS NULL OR project_id IN (#{current_project_ids}))", params[:id], session[:user].company_id ])
    if room.nil?
      render :nothing => true
      return
    end

    @shout = Shout.new(params[:shout])
    @shout.shout_channel_id = room.id
    @shout.user_id = session[:user].id
    n = session[:user].name.gsub(/[^\s\w]+/, '').split(" ")
    n = ["Anonymous"] if(n.nil? || n.empty?)
    @shout.nick = "#{n[0].capitalize} #{n[1..-1].collect{|e| e[0..0].upcase + "."}.join(' ')}".strip
    @shout.company_id = session[:user].company_id
    unless @shout.body.nil?
      if @shout.save
        render :update do |page|
          page.insert_html :bottom, "shout-list", :partial => 'shout'
          page.call 'Element.scrollTo', "shout_#{@shout.id}"
          page.visual_effect(:highlight, "shout_#{@shout.id}", :duration => 0.5)
        end
      else
        render :nothing => true
      end
    else
        render :nothing => true
    end

#    partial_to_string = render_to_string(:action => "list_ajax")
    #    Juggernaut.send("#{partial_to_string}", ["chat_#{session[:user].company_id}_#{room.id}"])
#    render :nothing => true
  end

  def list_ajax
    @shouts = Shout.find(:all, :conditions => ["company_id = ?", session[:user].company.id], :limit => 7, :order => "id desc")
  end
end
