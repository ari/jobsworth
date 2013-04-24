# encoding: UTF-8
# The filters added to this controller will be run for all controllers in the application.
# Likewise will all the methods added be available for all controllers.

#TODO: Clean this mess laterz
require 'digest/md5'

class ApplicationController < ActionController::Base
  before_filter :set_locale
  before_filter :authenticate_user!
  before_filter :current_sheet
  before_filter :set_mailer_url_options

  include UrlHelper
  include DateAndTimeHelper

  helper :task_filter
  helper :date_and_time
  helper :todos
  helper :tags
  helper :time_tracking
  helper :resources
  helper :work_logs

#  helper :all

  helper_method :last_active
  helper_method :render_to_string
  helper_method :current_user
  helper_method :tz
  helper_method :current_projects
  helper_method :current_project_ids
  helper_method :completed_milestone_ids
  helper_method :link_to_task
  helper_method :current_task_filter
  helper_method :current_templates
  helper_method :admin?, :logged_in?, :highlight_all

  #  protect_from_forgery :secret => '112141be0ba20082c17b05c78c63f357'
  def current_sheet
    if @current_sheet.nil? and not current_user.nil?
      @current_sheet = Sheet.where("user_id = ?", current_user.id).order('sheets.id').includes(:task).first
      unless @current_sheet.nil?
        if @current_sheet.task.nil?
          @current_sheet.destroy
          @current_sheet = nil
        end
      end
    end
    @current_sheet
  end

  def current_company
    @_current_company ||= current_user.try :company
  end

  delegate :projects, :project_ids, :to => :current_user, :prefix=> :current
  delegate :all_projects, :admin?, :tz,  :to => :current_user

  # List of completed milestone ids, joined with ,
  def completed_milestone_ids
    unless @milestone_ids
      @milestone_ids ||= Milestone.select("id").where("company_id = ? AND completed_at IS NOT NULL", current_user.company_id).collect{ |m| m.id }
      @milestone_ids = [-1] if @milestone_ids.empty?
    end
    @milestone_ids
  end

  def highlight_safe_html( text, k, raw = false )
    res = text.gsub(/(#{Regexp.escape(k)})/i, '{{{\1}}}')
    res = ERB::Util.h(res).gsub("{{{", "<strong>").gsub("}}}", "</strong>").html_safe unless raw
    res
  end

  def highlight_all( text, keys)
    keys.each do |k|
      text = highlight_safe_html( text, k, true)
    end
    ERB::Util.h(text).gsub("{{{", "<strong>").gsub("}}}", "</strong>").html_safe
  end

  def logged_in?
    true
  end

  def last_active
    session[:last_active] ||= Time.now.utc
  end

  ###
  # Which company does the served hostname correspond to?
  ###
  def company_from_subdomain
    if @company.nil?
      subdomain = request.subdomains.first if request.subdomains

      @company = Company.where("subdomain = ?", subdomain).first
      if Company.count == 1
        @company ||= Company.order("id asc").first
      end
    end

    return @company
  end

  def current_company
    current_user.try :company
  end

  # Redirects to the last page this user was on, or to the root url.
  # If the current request is using ajax, uses js to do the redirect.
  # If the tutorial hasn't been completed, sends them back to that page
  def redirect_from_last
    url = root_url

    if request.referer
      url = request.referer
    end

    url = url.gsub("format=js", "")
    redirect_using_js_if_needed(url)
  end

  private

  # Returns a link to the given task.
  # If highlight keys is given, that text will be highlighted in
  # the link.
  # NOTE: The method is deprecated and should be removed later.
  def link_to_task(task, truncate = true, highlight_keys = [])
    link = "<strong>#{task.issue_num}</strong> "
    if task.is_a? Template
      url = url_for(:id => task.task_num, :controller => 'task_templates', :action => 'edit')
    else
      url = url_for(:id => task.task_num, :controller => 'tasks', :action => 'edit')
    end

    html = {
      :class => "tasklink #{task.css_classes}",
    }

    text = truncate ? task.name : self.class.helpers.truncate(task.name, :length => 80)
    text = highlight_all(text, highlight_keys)

    link += self.class.helpers.link_to(text, url, html)
    return link.html_safe
  end

  # returns the current task filter (or a new, blank one
  # if none set)
  def current_task_filter
    @current_task_filter ||= TaskFilter.system_filter(current_user)
  end

  # Redirects to the given url. If the current request is using ajax,
  # javascript will be used to do the redirect.
  def redirect_using_js_if_needed(url)
    url = url_for(url)

    if !request.xhr?
      redirect_to url
    else
      render :js => "parent.document.location = '#{ url }'"
    end
  end

  def current_templates
    Template.where("project_id IN (?) AND company_id = ?", current_project_ids, current_user.company_id)
  end

  protected

  def authorize_user_is_admin
    unless current_user.admin?
      redirect_to root_path, alert: t('flash.alert.admin_permission_needed')
    end
  end

  def set_locale
    I18n.locale = current_user.try(:locale) || 'en_US'
  end

end
