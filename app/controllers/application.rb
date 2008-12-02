# The filters added to this controller will be run for all controllers in the application.
# Likewise will all the methods added be available for all controllers.
class ApplicationController < ActionController::Base

  include Misc

#  helper :all

  helper_method :last_active
  helper_method :render_to_string
  helper_method :current_user
  helper_method :current_users
  helper_method :all_users
  helper_method :tz
  helper_method :current_projects
  helper_method :current_project_ids
  helper_method :completed_milestone_ids
  helper_method :worked_nice

  before_filter :authorize, :except => [ :login, :validate, :signup, :take_signup, :forgotten_password,
                                         :take_forgotten, :show_logo, :about, :screenshots, :terms, :policy,
                                         :company_check, :subdomain_check, :unsubscribe, :shortlist_auth,
                                         :igoogle_setup, :igoogle
                                       ]
                                       
#  before_filter :clear_cache
                                       
  after_filter :set_charset
  after_filter OutputCompressionFilter

#  protect_from_forgery :secret => '112141be0ba20082c17b05c78c63f357'

  def current_user
    unless @current_user
      @current_user = User.find(session[:user_id], :include => [:company, :projects], :conditions => ["projects.completed_at IS NULL"])
    end
    @current_user
  end

  def current_users
    unless @current_users
      @current_users = User.find(:all, :conditions => " company_id=#{current_user.company_id} AND last_ping_at IS NOT NULL AND last_seen_at IS NOT NULL AND (last_ping_at > '#{3.minutes.ago.utc.to_s(:db)}' OR last_seen_at > '#{3.minutes.ago.utc.to_s(:db)}')", :order => "name" )
    end 
    @current_users
  end

  def all_users
    unless @all_users
      if current_user.company.restricted_userlist
        user_ids = [current_user.id]
        current_user.all_projects.each do |p|
          user_ids << p.users.collect{ |u| u.id }
        end

        @all_users = User.find(:all, :conditions => ["company_id = ? AND id IN (#{user_ids.uniq.join(',')})", current_user.company_id], :order => "name")
      else 
        @all_users = User.find(:all, :conditions => ["company_id = ?", current_user.company_id], :order => "name")
      end 
    end
    @all_users
  end
  
  def current_sheet
    unless @current_sheet
      @current_sheet = Sheet.find(:first, :conditions => ["user_id = ?", session[:user_id]], :order => 'sheets.id', :include => :task)
      unless @current_sheet.nil?
        if @current_sheet.task.nil?
          @current_sheet.destroy
          @current_sheet = nil
        end
      end
    end
    @current_sheet
  end
  
  def tz
    unless @tz
      @tz = Timezone.get(current_user.time_zone)
    end
    @tz
  end

  # Force UTF-8 for all text Content-Types
  def set_charset
    content_type = headers["Content-Type"] || 'text/html'
    if /^text\//.match(content_type)
      headers["Content-Type"] = "#{content_type}; charset=utf-8"
    end

  end

  # Make sure the session is logged in
  def authorize
    session[:history] ||= []

    # Remember the previous _important_ page for returning to after an edit / update.
    if( request.request_uri.include?('/list') || request.request_uri.include?('/search') || request.request_uri.include?('/edit_preferences') || 
        request.request_uri.include?('/timeline') || request.request_uri.include?('/gantt') || request.request_uri.include?('/shout') || 
        request.request_uri.include?('/forums') || request.request_uri.include?('/topics') ) && 
        !request.xhr?
      session[:history] = [request.request_uri] + session[:history][0,3] if session[:history][0] != request.request_uri
    end

#    session[:user_id] = User.find(:first, :offset => rand(1000).to_i).id
#    session[:user_id] = 1

    logger.info("remember[#{session[:remember_until]}]")
    
    # We need to re-authenticate
    if session[:user_id] && session[:remember_until] && session[:remember_until] < Time.now.utc
      session[:user_id] = nil
      session[:remember_until] = nil
    end
    
    if session[:user_id].to_i == 0
      if !(request.request_uri.include?('/login/login') || request.xhr?)
        session[:redirect] = request.request_uri 
      elsif session[:history] && session[:history].size > 0
        session[:redirect] = session[:history][0]
      end 
      
      # Generate a javascript redirect if user timed out without requesting a new page
      if request.xhr?
        render :update do |page|
          page.redirect_to :controller => 'login', :action => 'login'
        end
      else
        redirect_to "/login/login"
      end
    else
      # Refresh the User object
      # Subscribe general info channel
      begin
        session[:channels] = ["info_#{current_user.company_id}", "user_#{current_user.id}"]
      rescue
        flash['notice'] = 'Unable to find user'
        session[:user_id] = nil
        redirect_to "/login/login"
        return true
      end 
        
      current_user.shout_channels.each do |ch|
        session[:channels] << "channel_passive_#{ch.id}"
      end

      # Update last seen, to track online users
      if ['update_sheet_info', 'refresh_channels'].include?(request.path_parameters['action'])
        current_user.last_ping_at = Time.now.utc
      else 
        current_user.last_seen_at = Time.now.utc
        current_user.last_ping_at = Time.now.utc
      end 
      
      session[:remember_until] = Time.now.utc + ( session[:remember].to_i == 1 ? 1.month : 1.hour )
      
      current_user.save

      current_sheet
      
      # Set current locale
      Localization.lang(current_user.locale || 'en_US')
      
      # Update session with new filters, if they don't already exist
      session[:filter_severity] ||= "-10"
      session[:filter_priority] ||= "-10"

      if session[:redirect]
        redirect_to session[:redirect]
        session[:redirect] = nil
      end
    end
    true
  end


  # Parse <tt>1w 2d 3h 4m</tt> or <tt>1:2:3:4</tt> => minutes or seconds
  def parse_time(input, minutes = false)
    total = 0
    unless input.nil?
      miss = false
      reg = Regexp.new("(#{_('[wdhm]')})")
      input.downcase.gsub(reg,'\1 ').split(' ').each do |e|
        part = /(\d+)(\w+)/.match(e)
        if part && part.size == 3
          case  part[2]
          when _('w') then total += e.to_i * current_user.workday_duration * current_user.days_per_week
          when _('d') then total += e.to_i * current_user.workday_duration
          when _('h') then total += e.to_i * 60
          when _('m') then total += e.to_i
          else 
            miss = true
          end
        end
      end

      # Fallback to default english parsing
      if miss
        eng_total = 0
        reg = Regexp.new("([wdhm])")
        input.downcase.gsub(reg,'\1 ').split(' ').each do |e|
          part = /(\d+)(\w+)/.match(e)
          if part && part.size == 3
            case  part[2]
            when 'w' then eng_total += e.to_i * current_user.workday_duration * current_user.days_per_week
            when 'd' then eng_total += e.to_i * current_user.workday_duration
            when 'h' then eng_total += e.to_i * 60
            when 'm' then eng_total += e.to_i
            end
          end
        end
        
        if eng_total > total
          total = eng_total
        end
        
      end
      
      if total == 0
        times = input.split(':')
        while time = times.shift
          case times.size
          when 0 then total += time.to_i
          when 1 then total += time.to_i * 60
          when 2 then total += time.to_i * current_user.workday_duration
          when 3 then total += time.to_i * current_user.workday_duration * current_user.days_per_week
          end
        end
      end

      if total == 0 && input.to_i > 0
        total = input.to_i
      end

      total = total * 60 unless minutes
      
    end
    total
  end

  def parse_repeat(r)
    # every monday
    # every 15th
    # every last monday
    # every 3rd tuesday
    # every 01/02
    # every 12 days

    r = r.strip.downcase

    return unless r[0..5] == 'every '

    tokens = r[6..-1].split(' ')

    mode = ""
    args = []

    if tokens.size == 1
      Date::DAYNAMES.each do |d|
        if d.downcase == tokens[0]
          mode = "w"
          args[0] = tokens[0]
          break
        end
      end

      if mode == ""
        1.upto(Task::REPEAT_DATE.size) do |i|
          if Task::REPEAT_DATE[i].include? tokens[0]
            mode = 'm'
            args[0] = i
            break
          end
        end
      end

    end


  end


  # Redirect back to the last important page, forcing the tutorial unless that's completed.
  def redirect_from_last
    if session[:history] && session[:history].size > 0
      redirect_to(session[:history][0])
    else
      if current_user.seen_welcome.to_i == 0
        redirect_to('/activities/welcome')
      else
        redirect_to('/activities/list')
      end
    end
  end

  # List of Users current Projects ordered by customer_id and Project.name
  def current_projects
    current_user.projects
  end


  # List of current Project ids, joined with ,
  def current_project_ids
    unless @current_project_ids
      @current_project_ids = current_projects.collect{ |p| p.id }.join(',')
      @current_project_ids = "0" if @current_project_ids == ''
    end
    @current_project_ids
  end

  def all_projects
    current_user.all_projects
  end

  
  
  # List of completed milestone ids, joined with ,
  def completed_milestone_ids
    unless @milestone_ids
      @milestone_ids ||= Milestone.find(:all, :conditions => ["company_id = ? AND completed_at IS NOT NULL", current_user.company_id]).collect{ |m| m.id }.join(',')
      @milestone_ids = "-1" if @milestone_ids == ''
    end
    @milestone_ids
  end

  def worked_nice(minutes)
    format_duration(minutes, current_user.duration_format, current_user.workday_duration, current_user.days_per_week)
  end

  def highlight( text, k )
    t = text.gsub(/(#{Regexp.escape(k)})/i, '<strong>\1</strong>')
  end

  def highlight_all( text, keys )
    keys.each do |k|
      text = highlight(text, k)
    end
    text
  end

#  def rescue_action(exception)
#    log_exception(exception)
#    exception.is_a?(ActiveRecord::RecordInvalid) ? render_invalid_record(exception.record) : super
#  end

  def render_invalid_record(record)
    render :action => (record.new_record? ? 'new' : 'edit')
  end

  def admin?
    current_user.admin > 0
  end

  def logged_in?
    true
  end

  def last_active
    session[:last_active] ||= Time.now.utc
  end

  def link_to_task(task)
    "<strong><small>#{task.issue_num}</small></strong> <a href=\"/tasks/edit/#{task.id}\" class=\"tooltip#{task.css_classes}\" title=\"#{task.to_tip({ :duration_format => current_user.duration_format, :workday_duration => current_user.workday_duration, :days_per_week => current_user.days_per_week, :user => current_user })}\">#{task.name}</a>"
  end

  def double_escape(txt)
    res = txt.gsub(/channel-message-mine/,'channel-message-others')
    res = res.gsub(/\\n|\n|\\r|\r/,'') # remove linefeeds
    res = res.gsub(/'/, "\\\\'") # escape ' to \'
    res = res.gsub(/"/, '\\\\"')
    res
  end


end
