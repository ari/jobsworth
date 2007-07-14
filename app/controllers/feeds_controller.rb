#
# Provide a RSS feed of Project WorkLog activities.
# Author:: Erlend Simonsen (mailto:admin@clockingit.com)
#
class FeedsController < ApplicationController

  require 'rss/maker'
  require 'icalendar'

  include Icalendar

  session :off

  def get_action(log)
    if log.task && log.task_id > 0
      action = "Completed" if log.log_type == WorkLog::TASK_COMPLETED
      action = "Reverted" if log.log_type == WorkLog::TASK_REVERTED
      action = "Created" if log.log_type == WorkLog::TASK_CREATED
      action = "Modified" if log.log_type == WorkLog::TASK_MODIFIED
      action = "Commented" if log.log_type == WorkLog::TASK_COMMENT
      action = "Worked" if log.log_type == WorkLog::TASK_WORK_ADDED
      action = "Archived" if log.log_type == WorkLog::TASK_ARCHIVED
      action = "Restored" if log.log_type == WorkLog::TASK_RESTORED
    else
      action = "Note created" if log.log_type == WorkLog::PAGE_CREATED
      action = "Note deleted" if log.log_type == WorkLog::PAGE_DELETED
      action = "Note modified" if log.log_type == WorkLog::PAGE_MODIFIED
      action = "Deleted" if log.log_type == WorkLog::TASK_DELETED
      action = "Commit" if log.log_type == WorkLog::SCM_COMMIT
    end
    action
  end

  # Get the RSS feed, based on the secret key passed on the url
  def rss
    return if params[:id].empty? || params[:id].nil?

    @headers["Content-Type"] = "application/rss+xml"

    # Lookup user based on the secret key
    user = User.find(:first, :conditions => ["uuid = ?", params[:id]])

    if user.nil?
      render :nothing => true, :layout => false
      return
    end

    # Find all Project ids this user has access to
    pids = user.projects.find(:all, :order => "projects.customer_id, projects.name", :conditions => [ "projects.company_id = ? AND completed_at IS NULL", user.company_id ])

    # Find 50 last WorkLogs of the Projects
    unless pids.nil? || pids.empty?
      pids = pids.collect{|p|p.id}.join(',')
      @activities = WorkLog.find(:all, :order => "work_logs.started_at DESC", :limit => 50, :conditions => ["work_logs.project_id IN ( #{pids} )"], :include => [:user, :project, :customer, :task])
    else
      @activities = []
    end

    # Create the RSS
    content = RSS::Maker.make("2.0") do |m|
      m.channel.title = "#{user.company.name} Activities"
      m.channel.link = "http://#{user.company.subdomain}.clockingit.com/activities/list"
      m.channel.description = "Last changes from ClockingIT for #{user.name}@#{user.company.name}."
      m.items.do_sort = true # sort items by date

      @activities.each do |log|
        action = get_action(log)

        i = m.items.new_item
        i.title = " #{action}: #{log.task.issue_name}" unless log.task.nil?
        i.title ||= "#{action}"
        i.link = "http://#{user.company.subdomain}.clockingit.com/tasks/view/#{log.task.task_num}" unless log.task.nil?
        i.description = log.body unless log.body.nil? || log.body.empty?
        i.date = log.started_at
        i.author = log.user.name unless log.user.nil?
      end
    end

    # Render it inline
    render :inline => content.to_s, :layout => false

  end

  def to_localtime(user, time)
    DateTime.parse(TZInfo::Timezone.get(user.time_zone).utc_to_local(time).to_s)
  end

  def to_duration(dur)
    format_duration(dur, 1, 8 * 60).upcase
  end

  def ical_all
    ical(:all)
  end

  def ical(mode = :personal)

    return if params[:id].empty? || params[:id].nil?

    Localization.lang('en_US')

    @headers["Content-Type"] = "text/calendar"

    # Lookup user based on the secret key
    user = User.find(:first, :conditions => ["uuid = ?", params[:id]])

    if user.nil?
      render :nothing => true, :layout => false
      return
    end

    # Find all Project ids this user has access to
    pids = user.projects.find(:all, :order => "projects.customer_id, projects.name", :conditions => [ "projects.company_id = ? AND completed_at IS NULL", user.company_id ])

    # Find 50 last WorkLogs of the Projects
    unless pids.nil? || pids.empty?
      pids = pids.collect{|p|p.id}.join(',')
      if mode == :all
        @activities = WorkLog.find(:all, :order => "work_logs.started_at DESC", :conditions => ["work_logs.project_id IN ( #{pids} )"], :include => [:user, :project, :customer, { :task => :tags}])
        @tasks = Task.find(:all, :order => 'tasks.duration desc, tasks.name', :conditions => ["tasks.project_id IN (#{pids}) AND ((tasks.due_at is NOT NULL) OR (tasks.completed_at is NOT NULL))", ], :include => [:milestone, :tags] )
      else
        @activities = WorkLog.find(:all, :order => "work_logs.started_at DESC", :conditions => ["work_logs.project_id IN ( #{pids} ) AND work_logs.duration > 0 AND work_logs.user_id = ?", user.id], :include => [:user, :project, :customer, { :task => :tags } ])
        @tasks = user.tasks.find(:all, :order => 'tasks.duration desc, tasks.name', :conditions => ["tasks.project_id IN (#{pids}) AND ((tasks.due_at is NOT NULL AND tasks.due_at IS NOT NULL) OR (tasks.completed_at is NOT NULL))", ], :include => [:milestone, :tags] )
      end

      @milestones = Milestone.find(:all, :conditions => ["company_id = ? AND project_id IN (#{pids}) AND due_at IS NOT NULL", user.company_id])

    else
      @activities = []
      @milestones = []
      @tasks = []
    end

    cal = Calendar.new

    @milestones.each do |m|
      event = cal.event

      if m.completed_at
        event.start = to_localtime(user, m.completed_at)
      else
        event.start = to_localtime(user, m.due_at)
      end
      event.duration = "PT1M"
      event.uid =  "m#{m.id}_#{event.created}@#{user.company.subdomain}.clockingit.com"
      event.organizer = "MAILTO:#{m.user.email}"
      event.url = "http://#{user.company.subdomain}.clockingit.com/views/select_milestone/#{m.id}"
      event.summary = "Milestone: #{m.name}"

      description = m.description.gsub(/<[^>]*>/,'') if m.description
      description = description.gsub(/[\r]/, '')

      event.description = description if description && description.length > 0

    end


    @tasks.each do |t|
      event = cal.event
      todo = cal.todo

      unless t.completed_at
        todo.start = to_localtime(user, t.due_at - 12.hours)
      else
        todo.start = to_localtime(user, t.completed_at)
      end

      event.start = todo.start
      event.duration = "PT1M"

      todo.created = to_localtime(user, t.created_at)
      todo.uid =  "t#{t.id}_#{todo.created}@#{user.company.subdomain}.clockingit.com"
      todo.organizer = "MAILTO:#{t.users.first.email}" if t.users.size > 0
      todo.url = "http://#{user.company.subdomain}.clockingit.com/tasks/view/#{t.task_num}"
      todo.summary = "#{t.issue_name}"

      description = t.description.gsub(/<[^>]*>/,'').gsub(/[\r]/, '') if t.description

      todo.description = description if description && description.length > 0
      todo.categories = t.tags.collect{ |tag| tag.name.upcase } if(t.tags.size > 0)
      todo.percent = 100 if t.done?

      event.created = todo.created
      event.uid =  "te#{t.id}_#{todo.created}@#{user.company.subdomain}.clockingit.com"
      event.organizer = todo.organizer
      event.url = todo.url
      event.summary = "#{t.issue_name} - #{t.owners}" unless t.done?
      event.summary = "#{t.status_type} #{t.issue_name} (#{t.owners})" if t.done?
      event.description = todo.description
      event.categories = t.tags.collect{ |tag| tag.name.upcase } if(t.tags.size > 0)
    end


    @activities.each do |log|
      event = cal.event
      event.start = to_localtime(user, log.started_at)
#      event.end = to_localtime(user, log.started_at + (log.duration > 0 ? (log.duration*60) : 60) )
      event.duration = "PT" + to_duration(log.duration)
      event.created = to_localtime(user, log.task.created_at) unless log.task.nil?
      event.uid = "l#{log.id}_#{event.created}@#{user.company.subdomain}.clockingit.com"
      event.organizer = "MAILTO:#{log.user.email}"

      event.url = "http://#{user.company.subdomain}.clockingit.com/tasks/view/#{log.task.task_num}" unless log.task.nil?

      action = get_action(log)

      event.summary = "#{action}: #{log.task.issue_name} - #{log.user.name}" unless log.task.nil?
      event.summary = "#{action} #{to_duration(log.duration).downcase}: #{log.task.issue_name} - #{log.user.name}" if log.task && log.duration > 0
      event.summary ||= "#{action} - #{log.user.name}"
      description = log.body.gsub(/<[^>]*>/,'').gsub(/[\r]/, '') if log.body
      event.description = description if description && description.length > 0

      event.categories = log.task.tags.collect{ |t| t.name.upcase } if(log.task && log.task.tags.size > 0)
    end


    render :inline => cal.to_ical, :layout => false

  end

end
