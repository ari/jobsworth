# The filters added to this controller will be run for all controllers in the application.
# Likewise will all the methods added be available for all controllers.
class ApplicationController < ActionController::Base

  model :user
  model :company
  model :project
  model :sheet
  model :task

  before_filter :authorize, :except => [ :login, :validate, :signup, :take_signup, :forgotten_password, :take_forgotten, :show_logo, :rss, :about, :company_check, :subdomain_check ]

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

  # Format minutes => <tt>1w 2d 3h 3m</tt>
  def worked_nice(minutes)
    res = ''
    if minutes >= 60
      hours = minutes / 60
      minutes = minutes - (hours * 60)

      if hours >= 8
        days = hours / 8
        hours = hours - (days * 8)

        if days >= 5
          weeks = days / 5
          days = days - (weeks * 5)
          res += "#{weeks}w "
        end

        res += "#{days}d " if days > 0
      end


      res += "#{hours}h " if hours > 0
    end
    res += "#{minutes}m" if minutes > 0 || res == ''

    res
  end

  # Parse <tt>1w 2d 3h 4m</tt> => minutes or seconds
  def parse_time(input, minutes = false)
    total = 0
    unless input.nil?
      input.downcase.gsub(/([wdhm])/,'\1 ').split(' ').each do |e|
        case e[-1,1]
          when 'w' then total += e.to_i * 60 * 8 * 5
          when 'd' then total += e.to_i * 60 * 8
          when 'h' then total += e.to_i * 60
          when 'm' then total += e.to_i
        end
      end
      if total == 0 && input.to_i > 0
        total = input.to_i
        total = total * 60 unless minutes
      end

    end
    total
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

end
