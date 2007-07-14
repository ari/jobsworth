# The filters added to this controller will be run for all controllers in the application.
# Likewise will all the methods added be available for all controllers.
class ApplicationController < ActionController::Base

  include Misc

  model :user
  model :company
  model :project
  model :sheet
  model :task

  before_filter :authorize, :except => [ :login, :validate, :signup, :take_signup, :forgotten_password, :take_forgotten, :show_logo, :rss, :ical, :ical_all, :about, :company_check, :subdomain_check ]

  after_filter :set_charset
  after_filter OutputCompressionFilter

  helper_method :render_to_string

  # Force UTF-8 for all text Content-Types
  def set_charset
    content_type = @headers["Content-Type"] || 'text/html'
    if /^text\//.match(content_type)
      @headers["Content-Type"] = "#{content_type}; charset=\"utf-8\""
    end

  end

  # Make sure the session is logged in
  def authorize
    session[:history] ||= []

    # Remember the previous _important_ page for returning to after an edit / update.
    if( request.request_uri.include?('/list') || request.request_uri.include?('/search') || request.request_uri.include?('/edit_preferences') || request.request_uri.include?('/timeline')) && !request.xhr?
      session[:history] = [request.request_uri] + session[:history][0,3] if session[:history][0] != request.request_uri
    end

    if session[:user].nil?
      subdomain = request.subdomains.first

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
      session[:user] = User.find(session[:user].id)
      # Subscribe to chat and general info channels
      session[:channels] = ["chat_#{session[:user].company_id}", "info_#{session[:user].company_id}"]

      # Refresh work sheet
      session[:sheet] = Sheet.find(:first, :conditions => ["user_id = ?", session[:user].id], :order => 'id')

      # Update last seen, to track online users
      ActiveRecord::Base.connection.execute("update users set last_ping_at = '#{Time.now.utc.strftime("%Y-%m-%d %H:%M:%S")}' where id = #{session[:user].id}")

      # Set current locale
      Localization.lang(session[:user].locale || 'en_US')
    end
  end

  # Users preferred TimeZone
  def tz
    @tz ||= Timezone.get(session[:user].time_zone)
  end


  # Parse <tt>1w 2d 3h 4m</tt> or <tt>1:2:3:4</tt> => minutes or seconds
  def parse_time(input, minutes = false)
    total = 0
    unless input.nil?
      reg = Regexp.new("(#{_('[wdhm]')})")
      input.downcase.gsub(reg,'\1 ').split(' ').each do |e|
        part = /(\d+)(\w+)/.match(e)
        if part && part.size == 3
          case  part[2]
          when _('w') then total += e.to_i * session[:user].workday_duration * 5
          when _('d') then total += e.to_i * session[:user].workday_duration
          when _('h') then total += e.to_i * 60
          when _('m') then total += e.to_i
          end
        end
      end

      if total == 0
        times = input.split(':')
        while time = times.shift
          case times.size
          when 0 then total += time.to_i
          when 1 then total += time.to_i * 60
          when 2 then total += time.to_i * session[:user].workday_duration
          when 3 then total += time.to_i * session[:user].workday_duration * 5
          end
        end
      end

      if total == 0 && input.to_i > 0
        total = input.to_i
        total = total * 60 unless minutes
      end

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
      if session[:user].seen_welcome.to_i == 0
        redirect_to('/activities/welcome')
      else
        redirect_to('/activities/list')
      end
    end
  end

  # List of Users current Projects ordered by customer_id and Project.name
  def current_projects
    @current_projects ||= User.find(session[:user].id).projects.find(:all, :order => "projects.customer_id, projects.name",
                                                           :conditions => [ "projects.company_id = ? AND completed_at IS NULL", session[:user].company_id ], :include => :customer )
  end


  # List of current Project ids, joined with ,
  def current_project_ids
    projects = current_projects
    if projects.empty?
      @current_project_ids ||= "0"
    else
      @current_project_ids ||= projects.collect{|p|p.id}.join(',')
    end
    @current_project_ids
  end

  # List of completed milestone ids, joined with ,
  def completed_milestone_ids
    @milestone_ids ||= Milestone.find(:all, :conditions => ["company_id = ? AND completed_at IS NOT NULL", session[:user].company_id]).collect{ |m| m.id }.join(',')
    @milestone_ids = "-1" if @milestone_ids == ''
    @milestone_ids
  end

  def worked_nice(minutes)
    format_duration(minutes, session[:user].duration_format, session[:user].workday_duration)
  end

end
