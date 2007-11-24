class ShoutController < ApplicationController

#  cache_sweeper :shout_sweeper, :only => :add_ajax

  def list
    @rooms = ShoutChannel.find(:all, :conditions => ["(company_id IS NULL OR company_id = ?) AND (project_id IS NULL OR project_id IN (#{current_project_ids}))", session[:user].company_id],
                               :order => "company_id, project_id, name")
    session[:channels] << "lobby"
    session[:channels] << "lobby_#{session[:user].company_id}"
  end

  def update_channel
    room = ShoutChannel.find(:first, :conditions => ["id = ? AND (company_id IS NULL OR company_id = ?) AND (project_id IS NULL OR project_id IN (#{current_project_ids}))", params[:id], session[:user].company_id],
                              :order => "company_id, name")
    if room
      render :update do |page|
        page.replace "channel_#{room.id}", :partial => 'channel', :locals => { :channel => room }
        page.visual_effect(:highlight, "channel_#{room.id}", :duration => 0.5)
      end
    else
      render :nothing => true
    end
  end

  def transcripts
    if session[:user].admin > 9
      @rooms = ShoutChannel.find(:all, :conditions => ["(company_id IS NULL OR company_id = ?) AND (project_id IS NULL OR project_id IN (#{current_project_ids}))", session[:user].company_id],
                                 :order => "company_id, name")
    else
      @rooms = ShoutChannel.find(:all, :conditions => ["company_id = ? AND (project_id IS NULL OR project_id IN (#{current_project_ids}))", session[:user].company_id],
                                 :order => "company_id, name")
    end
    @transcripts = Transcript.find_all(session[:user].company_id, @rooms.collect(&:id) )
  end

  def transcript
    @room = ShoutChannel.find(:first, :conditions => ["id = ? AND (company_id IS NULL OR company_id = ?) AND (project_id IS NULL OR project_id IN (#{current_project_ids}))", params[:id], session[:user].company_id ])
    if @room.nil?
      redirect_to :action => 'list'
      return
    end

    @shouts = Shout.find(:all, :conditions => ["shout_channel_id = ? AND shouts.created_at > ? AND shouts.created_at < ?", @room.id, "#{params[:day]} 00:00:00", "#{params[:day]} 23:59:59"], :include => [:user])

    @prev = Shout.find(:first, :conditions => ["shout_channel_id = ? AND created_at < ? AND message_type = 0", @room.id, "#{params[:day]} 00:00:00"], :order => 'created_at desc')
    @next = Shout.find(:first, :conditions => ["shout_channel_id = ? AND created_at > ? AND message_type = 0", @room.id, "#{params[:day]} 23:59:59"], :order => 'created_at')
  end

  def room
    @room = ShoutChannel.find(:first, :conditions => ["id = ? AND (company_id IS NULL OR company_id = ?) AND (project_id IS NULL OR project_id IN (#{current_project_ids}))", params[:id], session[:user].company_id ])
    if @room.nil?
      redirect_to :action => 'list'
      return
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
      shout.body = "joined the room..."
      shout.save

      broadcast_shout(shout)

      Juggernaut.send( "do_update(#{session[:user].id}, '#{url_for(:controller => 'shout', :action => 'update_channel', :id => @room.id)}');", ["#{['lobby', @room.company_id].compact.join('_')}"] )

    end

    last = Shout.find(:first, :conditions => ["shout_channel_id = ? AND shouts.created_at > ?", @room.id, tz.now.utc.midnight.to_s(:db)])
    unless last
      check_timestamp(@room.id)
    end


    session[:channels] << "channel_#{@room.id}" unless session[:channels].include?("channel_#{@room.id}")
    session[:channels] -= ["channel_passive_#{@room.id}"] if session[:channels].include?("channel_passive_#{@room.id}")

  end

  def leave
    room = ShoutChannel.find(:first, :conditions => ["id = ? AND (company_id IS NULL OR company_id = ?) AND (project_id IS NULL OR project_id IN (#{current_project_ids}))", params[:id], session[:user].company_id ])
    session[:channels] -= ["channel_#{params[:id]}"]
    session[:channels] -= ["channel_passive_#{params[:id]}"]
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
      shout.body = "left the room..."
      shout.save

      check_timestamp(room.id)
      broadcast_shout(shout)

      Juggernaut.send( "do_update(#{session[:user].id}, '#{url_for(:controller => 'shout', :action => 'update_channel', :id => room.id)}');", ["#{['lobby', room.company_id].compact.join('_')}"] )

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
    @channel.public = 0
    @channel.project_id = nil if @channel.project_id == 0
    if @channel.save
      res = render_to_string :update do |page|
        page.insert_html :top, "channel-list", :partial => 'channel', :locals => { :room => @channel }
        page.visual_effect(:highlight, "channel_#{@channel.id}", :duration => 1.5)
        page['channel-add-container'].hide
      end
      Juggernaut.send("do_execute(#{session[:user].id}, '#{double_escape(res)}');", ["#{['lobby', @channel.company_id].compact.join('_')}"] )
      render :text => res
    else
      render :update do |page|
        page.visual_effect(:highlight, "channel-add-container", :duration => 0.5, :startcolor => "'#ff9999'")
      end
    end
  end

  def destroy_ajax
    room = ShoutChannel.find(:first, :conditions => ["id = ? AND company_id = ? AND (project_id IS NULL OR project_id IN (#{current_project_ids}))", params[:id], session[:user].company_id],
                              :order => "company_id, name")

    if room.nil? || (room.project_id.to_i == 0 && (!session[:user].admin?)) || ((room.project_id.to_i > 0) && (!session[:user].can?(room.project, 'grant')) )
      render :update do |page|
        page.visual_effect(:highlight, "channel_#{params[:id]}", :duration => 0.5, :startcolor => "'#ff9999'")
      end
    else
      redir = render_to_string :update do |page|
        page.redirect_to :action => 'list'
      end

      res = render :update do |page|
        page << "if($('channel_#{room.id}')){"
        page.visual_effect(:fade, "channel_#{room.id}")
        page << "}"
      end

      Juggernaut.send("do_execute(#{session[:user].id}, '#{double_escape(res)}');", ["#{['lobby', room.company_id].compact.join('_')}"] )
      Juggernaut.send("do_execute(#{session[:user].id}, '#{double_escape(redir)}');", ["channel_#{room.id}"] )

      room.destroy
    end
  end

  def destroy_transcript_ajax
    room = ShoutChannel.find(:first, :conditions => ["id = ? AND company_id = ? AND (project_id IS NULL OR project_id IN (#{current_project_ids}))", params[:id], session[:user].company_id],
                              :order => "company_id, name")

    if room.nil? || params[:day].nil? || params[:day].empty? || (room.project_id.to_i == 0 && (!session[:user].admin?)) || ((room.project_id.to_i > 0) && (!session[:user].can?(room.project, 'grant')) )
      render :update do |page|
        page.visual_effect(:highlight, "transcript_#{params[:id]}_#{params[:day]}", :duration => 0.5, :startcolor => "'#ff9999'")
      end
    else

      Shout.destroy_all(["shout_channel_id = ? AND shouts.created_at > ? AND shouts.created_at < ?", room.id, "#{params[:day]} 00:00:00", "#{params[:day]} 23:59:59"])

      render :update do |page|
        page.visual_effect(:fade, "transcript_#{room.id}_#{params[:day]}")
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
        present = render_present(@shout, last)
        passive = render_passive(@shout, last)

        Juggernaut.send("do_execute(#{session[:user].id}, '#{double_escape(present)}');", ["channel_#{room.id}"])
        Juggernaut.send("do_execute(#{session[:user].id}, '#{double_escape(passive)}');", ["channel_passive_#{room.id}"])

        render :text => date_stamp + present
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

#  def list_ajax
#    @shouts = Shout.find(:all, :conditions => ["company_id = ?", session[:user].company.id], :limit => 7, :order => "id desc")
#  end

  def refresh_channels
    @rooms = ShoutChannel.find(:all, :conditions => ["(company_id IS NULL OR company_id = ?) AND (project_id IS NULL OR project_id IN (#{current_project_ids}))", session[:user].company_id],
                               :order => "company_id, name")
    render :update do |page|
      @rooms.each do |room|
        page << "if($('channel_#{room.id}')){"
        page.replace "channel_#{room.id}", :partial => 'channel', :locals => { :channel => room }
        page << "}"
      end
    end
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

  def broadcast_shout(shout, last = nil)
    @shout = shout
    orig = render_to_string :update do |page|
      page.insert_html :bottom, "shout-list", :partial => 'shout', :locals => { :last => last }
      page.call 'Element.scrollTo', "shout_#{@shout.id}"
      page.visual_effect(:highlight, "shout_#{@shout.id}", :duration => 0.5)

      case shout.message_type
      when 1
        page.insert_html :bottom, "channel-users", "<div id=\"channel-user-#{shout.user_id}\">#{shout.user.name}</div>"
        page.visual_effect(:highlight, "channel-user-#{shout.user_id}", :duration => 0.5)
      when 2
        page.visual_effect(:fade, "channel-user-#{shout.user_id}")
      end
    end

    passive = render_passive(@shout)
    Juggernaut.send("do_execute(#{session[:user].id}, '#{double_escape(orig)}');", ["channel_#{shout.shout_channel_id}"])
    Juggernaut.send("do_execute(0, '#{double_escape(passive)}');", ["channel_passive_#{shout.shout_channel_id}"])

    # Back to text/html
    response.headers["Content-Type"] = 'text/html' unless request.xhr?

    orig
  end

  def render_present(shout, last = nil)
    @shout = shout
    present = render_to_string :update do |page|
      page.insert_html :bottom, "shout-list", :partial => 'shout', :locals => { :last => last }
      page.call 'Element.scrollTo', "shout_#{@shout.id}"
      page.visual_effect(:highlight, "shout_#{@shout.id}", :duration => 0.5)
    end
  end


  def render_passive(shout, last = nil)
    @shout = shout
    passive = render_to_string :update do |page|
      page.insert_html :bottom, "passive-chat", :partial => "shout", :locals => { :last => nil, :passive => true }
      page.visual_effect(:highlight, "shout_#{@shout.id}", :duration => 0.5)
      page.visual_effect(:appear, 'passive-chat-container', :duration => 0.5)
      page.delay(5.0) do
        page["shout_#{@shout.id}"].remove
        page << "if($$('#passive-chat .channel-message').length == 0) {"
        page.hide 'passive-chat-container'
        page << "}"
      end
    end
    passive = passive.gsub(/channel-message-others/, '') if @shout.message_type != 0
    passive
  end

  def double_escape(txt)
    res = txt.gsub(/channel-message-mine/,'channel-message-others')
    res = res.gsub(/\\n|\n|\\r|\r/,'') # remove linefeeds
    res = res.gsub(/'/, "\\\\'") # escape ' to \'
    res = res.gsub(/"/, '\\\\"')
    res
  end

end
