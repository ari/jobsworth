require "active_record_extensions"

# A task
#
# Belongs to a project, milestone, creator
# Has many tags, users (through task_owners), tags (through task_tags),
#   dependencies (tasks which should be done before this one) and
#   dependants (tasks which should be done after this one),
#   todos, and sheets
#
class Task < ActiveRecord::Base
  OPEN=0
  CLOSED=1
  WILL_NOT_FIX=2
  INVALID=3
  DUPLICATE=4
  MAX_STATUS=4
  include Misc

  belongs_to    :company
  belongs_to    :project
  belongs_to    :milestone

  has_many      :users, :through => :task_users, :source => :user
  has_many      :owners, :through =>:task_owners, :source=>:user
  has_many      :watchers, :through =>:task_watchers, :source=>:user

  #task_watcher and task_owner is subclasses of task_user
  has_many      :task_users, :dependent => :destroy
  has_many      :task_watchers, :dependent => :destroy
  has_many      :task_owners, :dependent => :destroy

  has_many      :work_logs, :dependent => :destroy, :order => "started_at asc"
  has_many      :attachments, :class_name => "ProjectFile", :dependent => :destroy
  has_many      :scm_changesets, :dependent =>:destroy

  belongs_to    :creator, :class_name => "User", :foreign_key => "creator_id"

  belongs_to    :old_owner, :class_name => "User", :foreign_key => "user_id"

  has_and_belongs_to_many  :tags, :join_table => 'task_tags'

  has_and_belongs_to_many  :dependencies, :class_name => "Task", :join_table => "dependencies", :association_foreign_key => "dependency_id", :foreign_key => "task_id", :order => 'dependency_id', :select => "tasks.*"
  has_and_belongs_to_many  :dependants, :class_name => "Task", :join_table => "dependencies", :association_foreign_key => "task_id", :foreign_key => "dependency_id", :order => 'task_id', :select=> "tasks.*"

  has_many :task_property_values, :dependent => :destroy, :include => [ :property ]
  accepts_nested_attributes_for :task_property_values, :allow_destroy => true

  has_many :task_customers, :dependent => :destroy
  has_many :customers, :through => :task_customers, :order => "customers.name asc"
  adds_and_removes_using_params :customers

  has_one       :ical_entry

  has_many      :todos, :order => "completed_at IS NULL desc, completed_at desc, position", :dependent => :destroy
  accepts_nested_attributes_for :todos

  has_many      :sheets
  has_and_belongs_to_many :resources

  validates_length_of           :name,  :maximum=>200, :allow_nil => true
  validates_presence_of         :name

  validates_presence_of   :company
  validates_presence_of   :project_id

  after_validation :fix_work_log_error

  before_create :set_task_num

  after_create { |t| Trigger.fire(t, "create") }

  after_save { |r|
    r.ical_entry.destroy if r.ical_entry
    project = r.project
    project.update_project_stats
    project.save

    if r.project.id != r.project_id
      # Task has changed projects, update counts of target project as well
      p = Project.find(r.project_id)
      p.update_project_stats
      p.save
    end

    r.milestone.update_counts if r.milestone
  }

  default_scope :conditions=>"tasks.type != 'Template'"

  named_scope :accessed_by, lambda { |user|
    {:readonly=>false, :joins=>"join projects on tasks.project_id = projects.id join project_permissions on project_permissions.project_id = projects.id join users on project_permissions.user_id = users.id", :conditions => ["projects.completed_at IS NULL and users.id=? and (project_permissions.can_see_unwatched = 1 or users.id in(select task_users.user_id from task_users where task_users.task_id=tasks.id))", user.id]}
  }
  named_scope :all_accessed_by, lambda {|user|
    {:readonly => false, :joins=>"join project_permissions on project_permissions.project_id = tasks.project_id join users on project_permissions.user_id = users.id", :conditions => ["users.id=? and (project_permissions.can_see_unwatched = 1 or users.id in(select task_users.user_id from task_users where task_users.task_id=tasks.id))", user.id]}
  }
  # w: 1, next day-of-week: Every _Sunday_
  # m: 1, next day-of-month: On the _10th_ day of every month
  # n: 2, nth day-of-week: On the _1st_ _Sunday_ of each month
  # y: 2, day-of-year: On _1_/_20_ of each year (mm/dd)
  # a: 1, add-days: _14_ days after each time the task is completed

  def next_repeat_date
    @date = nil

    return nil if self.repeat.nil?

    args = self.repeat.split(':')
    code = args[0]

    @start = self.due_at
    @start ||= Time.now.utc

    case code
    when ''  then
    when 'w' then
        @date = @start + (7 - @start.wday + args[1].to_i).days
    when 'm' then
        @date = @start.beginning_of_month.next_month.change(:day => (args[1].to_i))
    when 'n' then
        @date = @start.beginning_of_month.next_month.change(:day => 1)
      if args[2].to_i < @date.day
        args[2] = args[2].to_i + 7
      end
      @date = @date + (@date.day + args[2].to_i - @date.wday - 1).days
      @date = @date + (7 * (args[1].to_i - 1)).days
    when 'l' then
        @date = @start.next_month.end_of_month
      if args[1].to_i > @date.wday
        @date = @date.change(:day => @date.day - 7)
      end
      @date = @date.change(:day => @date.day - @date.wday + args[1].to_i)
    when 'y' then
        @date = @start.beginning_of_year.change(:year => @start.year + 1, :month => args[1].to_i, :day => args[2].to_i)
    when 'a' then
        @date = @start + args[1].to_i.days
    end
    @date.change(:hour => 23, :min => 59)
  end

  Task::REPEAT_DATE = [
                       [_('last')],
                       ['1st', 'first'], ['2nd', 'second'], ['3rd', 'third'], ['4th', 'fourth'], ['5th', 'fifth'], ['6th', 'sixth'], ['7th', 'seventh'], ['8th', 'eighth'], ['9th', 'ninth'], ['10th', 'tenth'],
                       ['11th', 'eleventh'], ['12th', 'twelwth'], ['13th', 'thirteenth'], ['14th', 'fourteenth'], ['15th', 'fifthteenth'], ['16th', 'sixteenth'], ['17th', 'seventeenth'], ['18th', 'eighthteenth'], ['19th', 'nineteenth'], ['20th', 'twentieth'],
                       ['21st', 'twentyfirst'], ['22nd', 'twentysecond'], ['23rd', 'twentythird'], ['24th', 'twentyfourth'], ['25th', 'twentyfifth'], ['26th', 'twentysixth'], ['27th', 'twentyseventh'], ['28th', 'twentyeight'], ['29th', 'twentyninth'], ['30th', 'thirtieth'], ['31st', 'thirtyfirst'],

                      ]

  def repeat_summary
    return "" if self.repeat.nil?

    args = self.repeat.split(':')
    code = args[0]

    case code
      when ''
      when 'w'
      "#{_'every'} #{_(Date::DAYNAMES[args[1].to_i]).downcase}"
      when 'm'
      "#{_'every'} #{Task::REPEAT_DATE[args[1].to_i][0]}"
      when 'n'
      "#{_'every'} #{Task::REPEAT_DATE[args[1].to_i][0]} #{_(Date::DAYNAMES[args[2].to_i]).downcase}"
      when 'l'
      "#{_'every'} #{_'last'} #{_(Date::DAYNAMES[args[2].to_i]).downcase}"
      when 'y'
      "#{_'every'} #{args[1].to_i}/#{args[2].to_i}"
      when 'a'
      "#{_'every'} #{args[1]} #{_ 'days'}"
    end
  end

  def parse_repeat(r)
    # every monday
    # every 15th

    # every last monday

    # every 3rd tuesday
    # every 1st may
    # every 12 days

    r = r.strip.downcase

    return unless r[0..(-1 + (_('every') + " ").length)] == _('every') + " "

    tokens = r[((_('every') + " ").length)..-1].split(' ')

    mode = ""
    args = []

    if tokens.size == 1

      if tokens[0] == _('day')
        # every day
        mode = "a"
        args[0] = '1'
      end

      if mode == ""
        # every friday
        0.upto(Date::DAYNAMES.size - 1) do |d|
          if Date::DAYNAMES[d].downcase == tokens[0]
            mode = "w"
            args[0] = d
            break
          end
        end
      end

      if mode == ""
        #every 15th
        1.upto(Task::REPEAT_DATE.size - 1) do |i|
          if Task::REPEAT_DATE[i].include? tokens[0]
            mode = 'm'
            args[0] = i
            break
          end
        end
      end

    elsif tokens.size == 2

      # every 2nd wednesday
      0.upto(Date::DAYNAMES.size - 1) do |d|
        if Date::DAYNAMES[d].downcase == tokens[1]
          1.upto(Task::REPEAT_DATE.size - 1) do |i|
            if Task::REPEAT_DATE[i].include? tokens[0]
              mode = 'n'
              args[0] = i
              args[1] = d
              break;
            end
          end
        end
      end

      if mode == ""
        # every 14 days
        if tokens[1] == _('days')
          mode = 'a'
          args[0] = tokens[0].to_i
        end
      end

      if mode == ""
        if tokens[0] == _('last')
          0.upto(Date::DAYNAMES.size - 1) do |d|
            if Date::DAYNAMES[d].downcase == tokens[1]
              mode = 'l'
              args[0] = d
              break
            end
          end
        end
      end

      if mode == ""
        # every may 15th / every 15th of may

      end

    end
    if mode != ""
      "#{mode}:#{args.join ':'}"
    else
      ""
    end
  end

  def resolved?
    status != 0
  end
  def open?
    status == 0
  end
  def closed?
    status == 1
  end

  def will_not_fix?
    status == 2
  end
  def invalid?
    status == 3
  end
  def duplicate?
    status == 4
  end
  def done?
    self.resolved? && self.completed_at != nil
  end

  def done
    self.resolved?
  end

  def ready?
    self.dependencies.reject{ |t| t.done? }.empty?
  end

  def active?
    self.hide_until.nil? || self.hide_until < Time.now.utc
  end

  def worked_on?
    self.sheets.size > 0
  end

  def time_left
    res = 0
    if self.due_at != nil
      res = self.due_at - Time.now.utc
    end
    res
  end

  def overdue?
    self.due_date ? (self.due_date.to_time <= Time.now.utc) : false
  end

  def scheduled_overdue?
    self.scheduled_date ? (self.scheduled_date.to_time <= Time.now.utc) : false
  end

  def started?
    worked_minutes > 0 || self.worked_on?
  end

  ###
  # This method return due_date - duration
  # It used only to display task in calendar. User should not start work on task when start_date come.
  # For date when user should start work on task we have schedule controller.
  # Again, do not use this method outside calendar view. And this method should be removed when schedule code will be fixed.
  ###
  def start_date
    return due_date if (duration.nil? or due_date.nil?)
    due_date - (duration/(60*8)).to_i.days
  end

  def due_date
    due = self.due_at
    due = self.milestone.due_at if(due.nil? && self.milestone_id.to_i > 0 && self.milestone)
    due
  end

  alias_method :due, :due_date

  def scheduled_date
    if self.scheduled?
      if self.scheduled_at?
        self.scheduled_at
      elsif self.milestone
        self.milestone.scheduled_date
      end
    else
      if self.due_at?
        self.due_at
      elsif self.milestone
        self.milestone.scheduled_date
      end
    end
  end

  def scheduled_due_at
    if self.scheduled?
      self.scheduled_at
    else
      self.due_at
    end
  end

  def scheduled_duration
    if self.scheduled?
      @attributes['scheduled_duration'].to_i
    else
      self.duration.to_i
    end
  end

  def recalculate_worked_minutes
    self.worked_minutes = WorkLog.sum(:duration, :conditions => ["task_id = ?", self.id]).to_i / 60
  end

  def minutes_left
    minutes_left_by self.duration
  end

  def scheduled_minutes_left
    minutes_left_by self.scheduled_duration
  end

  def overworked?
    ((self.duration.to_i - self.worked_minutes) < 0 && (self.duration.to_i) > 0)
  end

  def full_name
    if self.project
      [ERB::Util.h(self.project.full_name), self.full_tags].join(' / ').html_safe
    else
      ""
    end
  end

  def full_tags
    self.tags.collect{ |t| "<a href=\"/tasks/list/?tag=#{ERB::Util.h t.name}\" class=\"description\">#{ERB::Util.h t.name.capitalize.gsub(/\"/,'&quot;'.html_safe)}</a>" }.join(" / ").html_safe
  end

  def full_name_without_links
    [self.project.full_name, self.full_tags_without_links].join(' / ')
  end

  def full_tags_without_links
    self.tags.collect{ |t| t.name.capitalize }.join(" / ")
  end

  def issue_name
    "[##{self.task_num}] #{self[:name]}"
  end

  def issue_num
    if self.status > 1
    "<strike>##{self.task_num}</strike>".html_safe
    else
    "##{self.task_num}"
    end
  end

  def status_name
    "#{self.issue_num} #{self.name}"
  end

  def status_type
    self.company.statuses[self.status].name
  end


  def Task.status_types
    Company.first.statuses.all.collect {|a| a.name }
  end

  def owners_to_display
    o = self.owners.collect{ |u| u.name}.join(', ')
    o = "Unassigned" if o.nil? || o == ""
    o
  end

  def set_tags( tagstring )
    return false if (tagstring.nil? or  tagstring.gsub(' ','') == self.tagstring.gsub(' ',''))
    self.tags.clear
    tagstring.split(',').each do |t|
      tag_name = t.downcase.strip

      if tag_name.length == 0
        next
      end

      tag = Company.find(self.company_id).tags.find_or_create_by_name(tag_name)
      self.tags << tag unless self.tags.include?(tag)
    end
    self.company.tags.first.save unless self.company.tags.first.nil? #ugly, trigger tag save callback, needed to cache sweeper
    true
  end
  def tagstring
    tags.map { |t| t.name }.join(', ')
  end
  def set_tags=( tagstring )
    self.set_tags(tagstring)
  end
  def has_tag?(tag)
    name = tag.to_s
    self.tags.collect{|t| t.name}.include? name
  end

  def to_s
    self.name
  end

  def self.search(user, keys)
    tf = TaskFilter.new(:user => user)

    conditions = []
    keys.each do |k|
      conditions << "tasks.task_num = #{ k.to_i }"
    end
    name_conds = Search.search_conditions_for(keys, [ "tasks.name" ], :search_by_id => false)
    conditions << name_conds[1...-1] # strip off surounding parentheses

    conditions = "(#{ conditions.join(" or ") })"
    return tf.tasks(conditions)
  end

  def to_tip(options = { })
    unless @tip
      owners = "No one"
      owners = self.users.collect{|u| u.name}.join(', ') unless self.users.empty?

      res = "<table id=\"task_tooltip\" cellpadding=0 cellspacing=0>"
      res << "<tr><th>#{_('Summary')}</td><td>#{self.name}</tr>"
      res << "<tr><th>#{_('Project')}</td><td>#{self.project.full_name}</td></tr>"
      res << "<tr><th>#{_('Tags')}</td><td>#{self.full_tags}</td></tr>" unless self.full_tags.blank?
      res << "<tr><th>#{_('Assigned To')}</td><td>#{owners}</td></tr>"
      res << "<tr><th>#{_('Requested By')}</td><td>#{self.requested_by}</td></tr>" unless self.requested_by.blank?
      res << "<tr><th>#{_('Resolution')}</td><td>#{_(self.status_type)}</td></tr>"
      res << "<tr><th>#{_('Milestone')}</td><td>#{self.milestone.name}</td></tr>" if self.milestone_id.to_i > 0
      res << "<tr><th>#{_('Completed')}</td><td>#{options[:user].tz.utc_to_local(self.completed_at).strftime_localized(options[:user].date_format)}</td></tr>" if self.completed_at
      res << "<tr><th>#{_('Due Date')}</td><td>#{options[:user].tz.utc_to_local(due).strftime_localized(options[:user].date_format)}</td></tr>" if self.due
      unless self.dependencies.empty?
        res << "<tr><th valign=\"top\">#{_('Dependencies')}</td><td>#{self.dependencies.collect { |t| t.issue_name }.join('<br />')}</td></tr>"
      end
      unless self.dependants.empty?
        res << "<tr><th valign=\"top\">#{_('Depended on by')}</td><td>#{self.dependants.collect { |t| t.issue_name }.join('<br />')}</td></tr>"
      end
      res << "<tr><th>#{_('Progress')}</td><td>#{format_duration(self.worked_minutes, options[:duration_format], options[:workday_duration], options[:days_per_week])} / #{format_duration( self.duration.to_i, options[:duration_format], options[:workday_duration], options[:days_per_week] )}</tr>"
      res << "<tr><th>#{_('Description')}</th><td class=\"tip_description\">#{self.description_wrapped.gsub(/\n/, '<br/>')}</td></tr>" unless self.description.blank?
      res << "</table>"
      @tip = res
    end
    @tip
  end

  def description_wrapped
    unless description.blank?
      truncate( word_wrap(self.description, :line_width => 80), :length => 1000)
    else
      nil
    end
  end
  def css_classes
    unless @css
      @css= if self.open?
        ""
      elsif self.closed?
        " closed"
      else
        " invalid"
      end
    end
    @css
  end

  def todo_status
    todos.empty? ? "[#{_'To-do'}]" : "[#{sprintf("%.2f%%", todos.select{|t| t.completed_at }.size / todos.size.to_f * 100.0)}]"
  end

  def todo_count
    "#{sprintf("%d/%d", todos.select{|t| t.completed_at }.size, todos.size)}"
  end

  def order_date
    [self.created_at.to_i]
  end

  def worked_and_duration_class
    if worked_minutes > duration
      "overtime"
    else
      ""
    end
  end

  # Sets up custom properties using the given form params
  def properties=(params)
    ids=[]
    attributes= params.collect {  |prop_id, val_id|
      task_property_value= task_property_values.find_by_property_id(prop_id)
      if task_property_value.nil?
        hash={ :property_id => prop_id, :property_value_id => val_id}
      else
        ids << task_property_value.id
        hash={ :id=> task_property_value.id }
        if val_id.blank?
          hash[:_destroy]= 1
        else
          hash[:property_id]=prop_id
          hash[:property_value_id]=val_id
        end
      end
      hash
    }
    attributes += (self.task_property_values.collect(&:id) - ids).collect{ |id| { :id=>id, :_destroy=>1} }
    self.task_property_values_attributes= attributes
  end

  #set default properties for new task
  def set_default_properties
    task_property_values.clear
    self.company.properties.each do |property|
      task_property_values.build(:property_id=>property.id, :property_value_id=> property.default_value.id) unless property.default_value.nil?
    end
  end

  def csv_header
    ['Client', 'Project', 'Num', 'Name', 'Tags', 'User', 'Milestone', 'Due', 'Created', 'Completed', 'Worked', 'Estimated', 'Resolution'] +
      company.properties.collect { |property| property.name }
  end

  def to_csv
    [project.customer.name, project.name, task_num, name, tags.collect(&:name).join(','), owners_to_display, milestone.nil? ? nil : milestone.name, self.due_date, created_at, completed_at, worked_minutes, duration, status_type ] +
      company.properties.collect { |property| property_value(property).to_s }
  end

  def set_property_value(property, property_value)
    # remove the current one if it exists
    existing = task_property_values.detect { |tpv| tpv.property == property }
    if existing and existing.property_value != property_value
      task_property_values.delete(existing)
    end

    if property_value
      # only create a new one if property_value is set
      task_property_values.create(:property_id => property.id, :property_value_id => property_value.id)
    end
  end

  # Returns the value of the given property for this task
  def property_value(property)
    return unless property

    tpv = task_property_values.detect { |tpv| tpv.property.id == property.id }
    tpv.property_value if tpv
  end

  ###
  # This method return value of property named "Type"
  ###
  def type
    property_value(company.type_property)
  end

  ###
  # Returns an int to use for sorting this task. See Company.rank_by_properties
  # for more info.
  ###
  def sort_rank
    @sort_rank ||= company.rank_by_properties(self)
  end

  ###
  # A task is critical if it is in the top 20% of the possible
  # ranking using the companys sort.
  ###
  def critical?
    return false if company.maximum_sort_rank == 0

    sort_rank.to_f / company.maximum_sort_rank.to_f > 0.80
  end

  ###
  # A task is normal if it is not critical or low.
  ###
  def normal?
    !critical? and !low?
  end

  ###
  # A task is low if it is in the bottom 20% of the possible
  # ranking using the companys sort.
  ###
  def low?
    return false if company.maximum_sort_rank == 0

    sort_rank.to_f / company.maximum_sort_rank.to_f < 0.20
  end

  def users_to_notify(user_who_made_change=nil)
    if user_who_made_change and !user_who_made_change.receive_own_notifications?
      recipients= self.users.find(:all, :conditions=>  ["users.id != ? and users.receive_notifications = ?", user_who_made_change.id, true])
    else
      recipients= self.users.find(:all, :conditions=>  { :receive_notifications=>true})
      recipients<< user_who_made_change unless  user_who_made_change.nil? or recipients.include?(user_who_made_change)
    end
    recipients
  end

  ###
  # Returns an array of email addresses of people who should be
  # notified about changes to this task.
  ###
  def notification_email_addresses(user_who_made_change = nil)

    emails = users_to_notify(user_who_made_change).map { |u| u.email }

    # add in notify emails
    if !notify_emails.blank?
      emails += notify_emails_array
    end
    emails = emails.compact.map { |e| e.strip }

    # and finally remove dupes
    emails = emails.uniq

    return emails
  end


  ###
  # Sets the task watchers for this task.
  # Existing watchers WILL be cleared by this method.
  ###
  def set_watcher_ids(watcher_ids)
    return if watcher_ids.nil?

    self.task_watchers.destroy_all

    watcher_ids.each do |id|
      next if id.to_i == 0
      user = company.users.find(id)
      self.task_watchers.create(:user => user, :task => self)
    end
  end

  ###
  # Sets the owners of this task from owner_ids.
  # Existing owners WILL  be cleared by this method.
  ###
  def set_owner_ids(owner_ids)
    return if owner_ids.nil?

    self.task_owners.destroy_all

    owner_ids.each do |o|
      next if o.to_i == 0
      u = company.users.find(o.to_i)
      self.task_owners.create(:user => u, :task => self)
    end
  end

  ###
  # Sets up any task owners or watchers from the given params.
  # Any existings ones not in the given params will be removed.
  ###
  def set_users(params)
    all_users = params[:users] || []
    owners = params[:assigned] || []
    watchers = all_users - owners

    set_owner_ids(owners)
    set_watcher_ids(watchers)
  end

  ###
  # Sets the dependencies of this this from dependency_params.
  # Existing and unused dependencies WILL be cleared by this method,
  # only if user has access to this dependencies
  ###
  def set_dependency_attributes(dependency_params, user)
    return if dependency_params.nil?

    new_dependencies = []
    dependency_params.each do |d|
      d.split(",").each do |dep|
        dep.strip!
        next if dep.to_i == 0
        t = Task.accessed_by(user).find_by_task_num(dep)
        new_dependencies << t if t
      end
    end

    removed = self.dependencies.accessed_by(user) - new_dependencies
    self.dependencies.delete(removed)

    new_dependencies.each do |t|
      existing = self.dependencies.detect { |d| d.id == t.id }
      self.dependencies << t if !existing
    end

    self.save
  end

  ###
  # This method will mark this task as unread for any
  # setup watchers or task owners.
  # The exclude param should be a user or array of users whose unread
  # status will not be updated. For example, the person who wrote a
  # comment should probably be excluded.
  ###
  def mark_as_unread(exclude = [])
    exclude = [ exclude ].flatten # make sure it's an array.

    self.task_users.each do |n|
      n.update_attribute(:unread, true) if !exclude.include?(n.user)
    end
  end

  ###
  # Sets this task as read for user.
  # If read is passed, and false, sets the task
  # as unread for user.
  ###
  def set_task_read(user, read = true)
    user_notifications = self.task_users.select { |n| n.user == user }
    user_notifications.each do |n|
      n.update_attributes(:unread => !read)
    end
  end

  ###
  # Returns true if this task is marked as unread for user.
  ###
  def unread?(user)
    unread = false

    user_notifications = self.task_users.select { |n| n.user == user }
    user_notifications.each do |n|
      unread ||= n.unread?
    end

    return unread
  end

  ###
  # Sets up any links to resources that should be attached to this
  # task.
  # Clears any existings links to resources.
  ###
  def set_resource_attributes(params)
    return if !params

    resources.clear

    ids = params[:name].split(",")
    ids += params[:ids] if params[:ids] and params[:ids].any?

    ids.each do |id|
      self.resources << company.resources.find(id)
    end
  end

  ###
  # Custom validation for tasks.
  ###
  def validate
    res = true

    mandatory_properties = company.properties.select { |p| p.mandatory? }
    mandatory_properties.each do |p|
      if !property_value(p)
        res = false
        errors.add_to_base(_("%s is required", p.name))
      end
    end

    return res
  end

  # return a users mapped to the duration of time they have worked on this task
  def user_work
    if @user_work.nil?
      @user_work = {}
      logs = work_logs.all(:select => "user_id, sum(duration) as duration", :group => "user_id")
      logs.each do |l|
        user = User.find(l.user_id)
        @user_work[user] = l.duration if l.duration.to_i > 0
      end
    end

    return @user_work
  end
  def statuses_for_select_list
    company.statuses.collect{|s| [s.name]}.each_with_index{|s,i| s<< i }
  end
  def notify_emails_array
    (notify_emails || "").split(/$| |,/).map{ |email| email.strip.empty? ? nil : email.strip }.compact
  end

  def set_users_dependencies_resources(params, current_user)
    set_users(params)
    set_dependency_attributes(params[:dependencies], current_user)
    set_resource_attributes(params[:resource])
    self.attachments.find(params[:delete_files]).each{ |file| file.destroy }  rescue nil
  end
  def create_attachments(params, current_user)
    filenames = []
    unless params['tmp_files'].blank? || params['tmp_files'].select{|f| f != ""}.size == 0
      params['tmp_files'].each do |tmp_file|
        next if tmp_file.is_a?(String)
        task_file = ProjectFile.new()
        task_file.company = current_user.company
        task_file.customer = self.project.customer
        task_file.project = self.project
        task_file.task_id = self.id
        task_file.user_id = current_user.id
        task_file.file=tmp_file
        task_file.save!

        filenames << task_file.file_file_name
      end
    end
    return filenames
  end

  def repeat_task
    repeat = self.clone
    repeat.due_at = repeat.next_repeat_date
    repeat.tags << self.tags
    repeat.watchers= self.watchers
    repeat.owners = self.owners
    repeat.dependencies = self.dependencies
    repeat.save!
  end

  def update_group(user, group, value, icon = nil)
    if group == "milestone"
      val_arr = value.split("/")
      task_project = user.projects.find_by_name(val_arr[0])
      if user.can?(task_project, "milestone")
        pid = task_project.id
        if val_arr.size == 1
          self.milestone_id = nil
        else
          mid = Milestone.find(:first, :conditions => ['company_id = ? AND project_id = ? AND completed_at IS NULL AND LTRIM(name) = ?', user.company.id, pid, val_arr[1].strip]).id
          self.milestone_id = mid
        end
        self.project_id = pid
        save
      end
    elsif group == "resolution" && user.can?(self.project, 'close')
      p = Status.find_by_name_and_company_id(value, user.company_id).id
      self.status = (p - 1)
      save
    elsif prop = Property.find_by_company_id_and_name(user.company_id, group.camelize)
      if !value.blank?
        pv = PropertyValue.find_by_value_and_property_id(value, prop.id)
      elsif !icon.blank?
        icon = icon.split("?")[0]
        pv = PropertyValue.find_by_icon_url_and_property_id(icon, prop.id)
      end
      self.set_property_value(prop, pv)
    end
  end

  private

  def set_task_num
    company_id ||= company.id

    num = self.class.maximum('task_num', :conditions => ["company_id = ?", company_id])
    num ||= 0
    num += 1

    @attributes['task_num'] = num
  end

  # If creating a new work log with a duration, fails because it work log
  # has a mandatory attribute missing, the error message it the unhelpful
  # "Work logs in invalid". Fix that here
  def fix_work_log_error
    errors = self.errors.instance_variable_get("@errors")
    if errors.key?("work_logs")
      errors.delete("work_logs")
      self.work_logs.last.errors.each_full do |msg|
        self.errors.add_to_base(msg)
      end
    end
  end

  def minutes_left_by(duration)
    d = duration.to_i - self.worked_minutes
    d = 240 if d < 0 && duration.to_i > 0
    d = 0 if d < 0
    d
  end
end


# == Schema Information
#
# Table name: tasks
#
#  id                 :integer(4)      not null, primary key
#  name               :string(200)     default(""), not null
#  project_id         :integer(4)      default(0), not null
#  position           :integer(4)      default(0), not null
#  created_at         :datetime        not null
#  due_at             :datetime
#  updated_at         :datetime        not null
#  completed_at       :datetime
#  duration           :integer(4)      default(1)
#  hidden             :integer(4)      default(0)
#  milestone_id       :integer(4)
#  description        :text
#  company_id         :integer(4)
#  priority           :integer(4)      default(0)
#  updated_by_id      :integer(4)
#  severity_id        :integer(4)      default(0)
#  type_id            :integer(4)      default(0)
#  task_num           :integer(4)      default(0)
#  status             :integer(4)      default(0)
#  requested_by       :string(255)
#  creator_id         :integer(4)
#  notify_emails      :string(255)
#  repeat             :string(255)
#  hide_until         :datetime
#  scheduled_at       :datetime
#  scheduled_duration :integer(4)
#  scheduled          :boolean(1)      default(FALSE)
#  worked_minutes     :integer(4)      default(0)
#  type               :string(255)     default("Task")
#
# Indexes
#
#  index_tasks_on_type_and_task_num_and_company_id  (type,task_num,company_id) UNIQUE
#  tasks_project_id_index                           (project_id,milestone_id)
#  tasks_company_id_index                           (company_id)
#  tasks_project_completed_index                    (project_id,completed_at)
#  index_tasks_on_milestone_id                      (milestone_id)
#  tasks_due_at_idx                                 (due_at)
#

