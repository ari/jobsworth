# The filters added to this controller will be run for all controllers in the application.
# Likewise will all the methods added be available for all controllers.
class ApplicationController < ActionController::Base

  model :user
  model :company
  model :project
  model :sheet
  model :task

  before_filter :authorize, :except => [ :login, :validate, :signup, :take_signup, :forgotten_password, :take_forgotten, :show_logo, :rss, :about ]

  after_filter :set_charset
  after_filter OutputCompressionFilter

  helper_method :render_to_string

  def set_charset
    content_type = @headers["Content-Type"] || 'text/html'
    if /^text\//.match(content_type)
      @headers["Content-Type"] = "#{content_type}; charset=\"utf-8\""
    end

  end

  def authorize
    session[:history] ||= []

    if( request.request_uri.include?('/list') || request.request_uri.include?('/search') || request.request_uri.include?('/edit_preferences') || request.request_uri.include?('/timeline')) && !request.xhr?
      session[:history] = [request.request_uri] + session[:history][0,3] if session[:history][0] != request.request_uri
    end

    if session[:user].nil?

      subdomain = request.subdomains.first

      if request.xhr?
        render :update do |page|
          page.redirect_to :controller => 'login', :action => 'login'
        end
      else
        redirect_to "/login/login"
      end
    else

      session[:user] = User.find(session[:user].id)

      session[:channels] = ["chat_#{session[:user].company_id}", "info_#{session[:user].company_id}"]

      ActiveRecord::Base.connection.execute("update users set last_ping_at = '#{Time.now.utc.strftime("%Y-%m-%d %H:%M:%S")}' where id = #{session[:user].id}")
    end
  end

  def tz
    Timezone.get(session[:user].time_zone)
  end

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

  def current_projects
    User.find(session[:user].id).projects.find(:all, :order => "projects.customer_id, projects.name",
                                                           :conditions => [ "projects.company_id = ?", session[:user].company_id ], :include => :customer )
  end



  def current_project_ids
    projects = current_projects
    if projects.empty?
      "0"
    else
      projects.collect{|p|p.id}.join(',')
    end
  end

end
