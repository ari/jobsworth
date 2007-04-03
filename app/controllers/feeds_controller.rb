#
# Provide a RSS feed of Project WorkLog activities.
# Author:: Erlend Simonsen (mailto:admin@clockingit.com)
#
class FeedsController < ApplicationController

  require 'rss/maker'

  session :off

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

        if log.task && log.task_id > 0
          action = "Completed" if log.log_type == WorkLog::TASK_COMPLETED
          action = "Reverted" if log.log_type == WorkLog::TASK_REVERTED
          action = "Created" if log.log_type == WorkLog::TASK_CREATED
          action = "Modified" if log.log_type == WorkLog::TASK_MODIFIED
          action = "Commented" if log.log_type == WorkLog::TASK_COMMENT
          action = "Work done" if log.log_type == WorkLog::TASK_WORK_ADDED
          action = "Archived" if log.log_type == WorkLog::TASK_ARCHIVED
          action = "Restored" if log.log_type == WorkLog::TASK_RESTORED
        else
          action = "Note created" if log.log_type == WorkLog::PAGE_CREATED
          action = "Note deleted" if log.log_type == WorkLog::PAGE_DELETED
          action = "Note modified" if log.log_type == WorkLog::PAGE_MODIFIED
          action = "Deleted" if log.log_type == WorkLog::TASK_DELETED
          action = "Commit" if log.log_type == WorkLog::SCM_COMMIT
        end

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

end
