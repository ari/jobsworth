class ShoutController < ApplicationController

#  cache_sweeper :shout_sweeper, :only => :add_ajax

  def list
    @rooms = ShoutChannel.find(:all, :conditions => ["(company_id IS NULL OR company_id = ?) AND (project_id IS NULL OR project_id IN (#{current_project_ids}))", session[:user].company_id],
                               :order => "company_id, name")
  end

  def room
    @room = ShoutChannel.find(:first, :conditions => ["id = ? AND (company_id IS NULL OR company_id = ?) AND (project_id IS NULL OR project_id IN (#{current_project_ids}))", params[:id], session[:user].company_id ])
    unless @room
      redirect_to :action => 'list'
    end

    unless User.find(session[:user].id).shout_channels.include?(@room)

      s = ShoutChannelSubscription.new( :user_id => session[:user].id, :shout_channel_id => @room.id)
      s.save

      check_timestamp(@room.id)

      shout = Shout.new
      shout.user_id = session[:user].id
      shout.company_id = @room.company_id
      shout.nick = shout_nick(session[:user].name)
      shout.shout_channel_id = @room.id
      shout.message_type = 1
      shout.body = "entered..."
      shout.save

      broadcast_shout(shout)

    end
    session[:channels] << "channel_#{@room.id}" unless session[:channels].include?("channel_#{@room.id}")
    session[:channels] << "channel_offline_#{@room.id}" if session[:channels].include?("channel_offline_#{@room.id}")

  end

  def leave
    room = ShoutChannel.find(:first, :conditions => ["id = ? AND (company_id IS NULL OR company_id = ?) AND (project_id IS NULL OR project_id IN (#{current_project_ids}))", params[:id], session[:user].company_id ])
    session[:channels] -= ["channel_#{params[:id]}"]
    subs = ShoutChannelSubscription.find(:all, :conditions => ["user_id = ? AND shout_channel_id = ?", session[:user].id, params[:id]])
    unless subs.empty?
      subs.each do |s|
        s.destroy
      end

      shout = Shout.new
      shout.user_id = session[:user].id
      shout.nick = shout_nick(session[:user].name)
      shout.company_id = room.company_id
      shout.shout_channel_id = room.id
      shout.message_type = 2
      shout.body = "left..."
      shout.save

      check_timestamp(room.id)
      broadcast_shout(shout)
    end

    redirect_to :action => 'list'
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

    date_stamp = check_timestamp(room.id)

    last = room.shouts.find(:first, :order => "created_at desc", :limit => 1)

    @shout = Shout.new(params[:shout])
    @shout.shout_channel_id = room.id
    @shout.user_id = session[:user].id
    @shout.nick = shout_nick(session[:user].name)
    @shout.company_id = room.company_id
    if @shout.body && @shout.body.length > 0
      if @shout.save
        orig = render_to_string :update do |page|
          page.insert_html :bottom, "shout-list", :partial => 'shout', :locals => { :last => last }
          page.call 'Element.scrollTo', "shout_#{@shout.id}"
          page.visual_effect(:highlight, "shout_#{@shout.id}", :duration => 0.5)
        end

        # Horrible escaping... Bah.
        res = orig.gsub(/channel-message-mine/,'')
        res = res.gsub(/\\n|\n/,'')
        res = res.gsub(/[']/, '\\\\\'')
        res = res.gsub(/\\"/, '\\\\\"')

        Juggernaut.send("do_execute(#{session[:user].id}, '#{res}');", ["channel_#{room.id}"])

        render :text => date_stamp + orig
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

  def shout_nick(name)
    n = nil
    n = name.gsub(/[^\s\w]+/, '').split(" ") if name
    n = ["Anonymous"] if(n.nil? || n.empty?)

    "#{n[0].capitalize} #{n[1..-1].collect{|e| e[0..0].upcase + "."}.join(' ')}".strip
  end

  def check_timestamp(rid)
    stamp = Time.at((Time.now.to_i / 300) * 300).utc
    room = ShoutChannel.find(rid)
    last = room.shouts.find(:first, :conditions => ["message_type = 3 AND created_at >= '#{10.minutes.ago.utc.to_s(:db)}'"], :order => "created_at desc", :limit => 1)
    unless last
      shout = Shout.new
      shout.user_id = nil
      shout.nick = "#{stamp.strftime('%d %h')}"
      shout.shout_channel_id = room.id
      shout.company_id = room.company_id
      shout.message_type = 3
      shout.body = "#{stamp.strftime('%H:%M')}"
      shout.created_at = stamp.to_s(:db)
      shout.save
      return broadcast_shout(shout)
    end
    return ""
  end

  def broadcast_shout(shout)
    @shout = shout
    orig = render_to_string :update do |page|
      page.insert_html :bottom, "shout-list", :partial => 'shout', :locals => { :last => nil }
      page.visual_effect(:highlight, "shout_#{@shout.id}", :duration => 0.5)
      page.call 'Element.scrollTo', "shout_#{@shout.id}"

      case shout.message_type
      when 1
        page.insert_html :bottom, "channel-users", "<div id=\"channel-user-#{shout.user_id}\">#{shout.user.name}</div>"
        page.visual_effect(:highlight, "channel-user-#{shout.user_id}", :duration => 0.5)
      when 2
        page.visual_effect(:fade, "channel-user-#{shout.user_id}")
      end
    end

    # Horrible escaping... Bah.
    res = orig.gsub(/channel-message-mine/,'')
    res = res.gsub(/\\n|\n/,'')
    res = res.gsub(/[']/, '\\\\\'')
    res = res.gsub(/\\"/, '\\\\\"')

    Juggernaut.send("do_execute(#{session[:user].id}, '#{res}');", ["channel_#{shout.shout_channel_id}"])

    # Back to text/html
    response.headers["Content-Type"] = 'text/html'

    orig
  end

end
