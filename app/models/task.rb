# A task
#
# Belongs to a project, milestone, creator
# Has many tags, users (through task_owners), tags (through task_tags),
#   dependencies (tasks which should be done before this one) and 
#   dependants (tasks which should be done after this one),
#   todos, and sheets
#

class Task < ActiveRecord::Base

  include Misc

  acts_as_ferret( { :fields => { 'company_id' => {},
                      'project_id' => {},
                      'full_name' => { :boost => 1.5 },
                      'name' => { :boost => 2.0 },
                      'issue_name' => { :boost => 0.8 },
                      'description' => { :boost => 1.7},
                      'requested_by' => { :boost => 0.7 }
                    },
                    :remote => true
                  } )

  belongs_to    :company
  belongs_to    :project
  belongs_to    :milestone
  has_many      :users, :through => :task_owners, :source => :user
  has_many      :task_owners, :dependent => :destroy

  has_many      :work_logs, :dependent => :destroy
  has_many      :attachments, :class_name => "ProjectFile", :dependent => :destroy

  has_many      :notifications, :dependent => :destroy
  has_many      :watchers, :through => :notifications, :source => :user

  belongs_to    :creator, :class_name => "User", :foreign_key => "creator_id"

  belongs_to    :old_owner, :class_name => "User", :foreign_key => "user_id"

  has_and_belongs_to_many  :tags, :join_table => 'task_tags'

  has_and_belongs_to_many  :dependencies, :class_name => "Task", :join_table => "dependencies", :association_foreign_key => "dependency_id", :foreign_key => "task_id", :order => 'dependency_id'
  has_and_belongs_to_many  :dependants, :class_name => "Task", :join_table => "dependencies", :association_foreign_key => "task_id", :foreign_key => "dependency_id", :order => 'task_id'

  has_one       :ical_entry

  has_many      :todos, :order => "completed_at IS NULL desc, completed_at desc, position"
  has_many      :sheets

  validates_length_of           :name,  :maximum=>200, :allow_nil => true
  validates_presence_of         :name
  
  validates_presence_of		:company
  validates_presence_of		:project

  after_save { |r|
    r.ical_entry.destroy if r.ical_entry

    r.project.critical_count = Task.count(:conditions => ["project_id = ? AND (severity_id + priority)/2 > 0  AND completed_at IS NULL", r.project.id])
    r.project.normal_count = Task.count(:conditions => ["project_id = ? AND (severity_id + priority)/2 = 0 AND completed_at IS NULL", r.project.id])
    r.project.low_count = Task.count(:conditions => ["project_id = ? AND (severity_id + priority)/2 < 0 AND completed_at IS NULL", r.project.id])
    r.project.open_tasks = nil
    r.project.total_tasks = nil
    r.project.save

    if r.project.id != r.project_id
      # Task has changed projects, update counts of target project as well
      p = Project.find(r.project_id)
      p.critical_count = Task.count(:conditions => ["project_id = ? AND (severity_id + priority)/2 > 0  AND completed_at IS NULL", p.id])
      p.normal_count = Task.count(:conditions => ["project_id = ? AND (severity_id + priority)/2 = 0 AND completed_at IS NULL", p.id])
      p.low_count = Task.count(:conditions => ["project_id = ? AND (severity_id + priority)/2 < 0 AND completed_at IS NULL", p.id])
      p.open_tasks = nil
      p.total_tasks = nil
      p.save
    end
    
    r.milestone.update_counts if r.milestone
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
    when ''  :
    when 'w' :
        @date = @start + (7 - @start.wday + args[1].to_i).days
    when 'm' :
        @date = @start.beginning_of_month.next_month.change(:day => (args[1].to_i))
    when 'n' :
        @date = @start.beginning_of_month.next_month.change(:day => 1)
      if args[2].to_i < @date.day
        args[2] = args[2].to_i + 7
      end
      @date = @date + (@date.day + args[2].to_i - @date.wday - 1).days
      @date = @date + (7 * (args[1].to_i - 1)).days
    when 'l' :
        @date = @start.next_month.end_of_month
      if args[1].to_i > @date.wday
        @date = @date.change(:day => @date.day - 7)
      end
      @date = @date.change(:day => @date.day - @date.wday + args[1].to_i)
    when 'y' :
        @date = @start.beginning_of_year.change(:year => @start.year + 1, :month => args[1].to_i, :day => args[2].to_i)
    when 'a' :
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

  def done?
    self.status > 1 && self.completed_at != nil
  end

  def done
    self.status > 1
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

  def set_task_num(company_id)
    @attributes['task_num'] = Task.maximum('task_num', :conditions => ["company_id = ?", company_id]) + 1 rescue 1
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
  
  def due_date
    if self.due_at?
      self.due_at
    elsif self.milestone_id.to_i > 0 && milestone && milestone.due_at?
      milestone.due_at
    else 
      nil
    end 
  end

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
    d = self.duration.to_i - self.worked_minutes 
    d = 240 if d < 0 && self.duration.to_i > 0
    d = 0 if d < 0
    d
  end

  def scheduled_minutes_left
    d = self.scheduled_duration.to_i - self.worked_minutes 
    d = 240 if d < 0 && self.scheduled_duration.to_i > 0
    d = 0 if d < 0
    d
  end 

  def overworked?
    ((self.duration.to_i - self.worked_minutes) < 0 && (self.duration.to_i) > 0)
  end
  
  def full_name
    if self.project
      [self.project.full_name, self.full_tags].join(' / ')
    else 
      ""
    end 
  end

  def full_tags
    self.tags.collect{ |t| "<a href=\"/tasks/list/?tag=#{t.name}\" class=\"description\">#{t.name.capitalize.gsub(/\"/,'&quot;')}</a>" }.join(" / ")
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
    "<strike>##{self.task_num}</strike>"
    else
    "##{self.task_num}"
    end
  end

  def status_name
    "#{self.issue_num} #{self.name}"
  end

  def issue_type
    Task.issue_types[self.type_id]
  end

  def Task.issue_types
    ["Task", "New Feature", "Defect", "Improvement"]
  end

  def status_type
    Task.status_types[self.status]
  end

  def Task.status_type(type)
    Task.status_types[type]
  end

  def Task.status_types
    ["Open", "In Progress", "Closed", "Won't fix", "Invalid", "Duplicate"]
  end

  def priority_type
    Task.priority_types[self.priority]
  end

  def Task.priority_types
    {  -2 => "Lowest", -1 => "Low", 0 => "Normal", 1 => "High", 2 => "Urgent", 3 => "Critical" }
  end

  def severity_type
    Task.severity_types[self.severity_id]
  end

  def Task.severity_types
    { -2 => "Trivial", -1 => "Minor", 0 => "Normal", 1 => "Major", 2 => "Critical", 3 => "Blocker"}
  end

  def owners
    o = self.users.collect{ |u| u.name}.join(', ')
    o = "Unassigned" if o.nil? || o == ""
    o
  end

  def set_tags( tagstring )
    return false unless tagstring
    self.tags.clear
    tagstring.split(',').each do |t|
      tag_name = t.downcase.strip

      if tag_name.length == 0
        next
      end

      tag = Company.find(self.company_id).tags.find_or_create_by_name(tag_name)
      self.tags << tag unless self.tags.include?(tag)
    end
    true
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

  # { :clockingit => [ {:tasks => []} ] }

  def Task.filter_by_tag(tag, tasks)
    matching = []
    tasks.each do | t |
      if t.has_tag? tag
        matching += [t]
      end
    end
    matching
  end


  def Task.group_by_tags(tasks, tags, done_tags, depth)
    groups = { }

    tags -= done_tags
    tags.each do |tag|

      done_tags += [tag]


      unless tasks.nil?  || tasks.size == 0

        matching_tasks = Task.filter_by_tag(tag,tasks)
        unless matching_tasks.nil? || matching_tasks.size == 0
          tasks -= matching_tasks
          groups[tag] = Task.group_by_tags(matching_tasks, tags, done_tags, depth+1)
        end


      end

      done_tags -= [tag]

    end
    if groups.keys.size > 0 && !tasks.nil? && tasks.size > 0
      [tasks, groups]
    elsif groups.keys.size > 0
      [groups]
    else
      [tasks]
    end
  end

  def Task.tag_groups(company_id, tags, tasks)
    Task.group_by_tags(tasks,tags,[], 0)
  end

  def Task.group_by(tasks, items, done_items = [], depth = 0)
    groups = OrderedHash.new

    items -= done_items
    items.each do |item|
      unless tasks.nil?
        matching_tasks = tasks.select do |t|
          yield(t,item)
        end
      end
      tasks -= matching_tasks
      unless matching_tasks.empty?
        groups[item] = matching_tasks
      else
        groups[item] = []
      end
    end

    if groups.keys.size > 0
      [tasks, groups]
    else
      [tasks]
    end
  end

  def Task.tagged_with(tag, options = {})
    tags = []
    if tag.is_a? Tag
      tags = [tag.name]
    elsif tag.is_a? String
      tags = tag.include?(",") ? tag.split(',') : [tag]
    elsif tag.is_a? Array
      tags = tag
    end

    task_ids = ''
    if options[:filter_user].to_i > 0
      task_ids = User.find(options[:filter_user].to_i).tasks.collect { |t| t.id }.join(',')
    end

    if options[:filter_user].to_i < 0
      task_ids = Task.find(:all, :select => "tasks.*", :joins => "LEFT OUTER JOIN task_owners t_o ON tasks.id = t_o.task_id", :conditions => ["tasks.company_id = ? AND t_o.id IS NULL", options[:company_id]]).collect { |t| t.id }.join(',')
    end

    completed_milestones_ids = Milestone.find(:all, :conditions => ["company_id = ? AND completed_at IS NOT NULL", options[:company_id]]).collect{ |m| m.id}.join(',')

    task_ids_str = "tasks.id IN (#{task_ids})" if task_ids != ''
    task_ids_str = "tasks.id = 0" if task_ids == ''

    sql = "SELECT tasks.* FROM (tasks, task_tags, tags) LEFT OUTER JOIN milestones ON milestones.id = tasks.milestone_id  LEFT OUTER JOIN projects ON projects.id = tasks.project_id WHERE task_tags.tag_id=tags.id AND tasks.id = task_tags.task_id"
    sql << " AND (" + tags.collect { |t| sanitize_sql(["tags.name='%s'",t.downcase.strip]) }.join(" OR ") + ")"
    sql << " AND tasks.company_id=#{options[:company_id]}" if options[:company_id]
    sql << " AND tasks.project_id IN (#{options[:project_ids]})" if options[:project_ids]
    sql << " AND tasks.hidden = 1" if options[:filter_status].to_i == -2
    sql << " AND tasks.hidden = 0" if options[:filter_status].to_i != -2
    sql << " AND tasks.status = #{options[:filter_status]}" unless (options[:filter_status].to_i == -1 || options[:filter_status].to_i == 0 || options[:filter_status].to_i == -2)
    sql << " AND (tasks.status = 0 OR tasks.status = 1)" if options[:filter_status].to_i == 0
    sql << " AND #{task_ids_str}" unless options[:filter_user].to_i == 0
    sql << " AND tasks.milestone_id = #{options[:filter_milestone]}" if options[:filter_milestone].to_i > 0
    sql << " AND (tasks.milestone_id IS NULL OR tasks.milestone_id = 0)" if options[:filter_milestone].to_i < 0
    sql << " AND (tasks.milestone_id NOT IN (#{completed_milestones_ids}) OR tasks.milestone_id IS NULL)" if completed_milestones_ids != ''
    sql << " AND projects.customer_id = #{options[:filter_customer]}" if options[:filter_customer].to_i > 0
    sql << " GROUP BY tasks.id"
    sql << " HAVING COUNT(tasks.id) = #{tags.size}"
    sql << " ORDER BY tasks.completed_at is NOT NULL, tasks.completed_at DESC"
    sql << ", #{options[:sort]}" if options[:sort] && options[:sort].length > 0

    find_by_sql(sql)
  end

  def self.full_text_search(q, options = {})
    return nil if q.nil? or q==""
    default_options = {:limit => 20, :page => 1}
    options = default_options.merge options
    options[:offset] = options[:limit] * (options.delete(:page).to_i-1)
    results = Task.find_by_contents(q, options)
    return [results.total_hits, results]
  end

  def due
    due = self.due_at
    due = self.milestone.due_at if(due.nil? && self.milestone_id.to_i > 0 && self.milestone)
    due
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
      res << "<tr><th>#{_('Status')}</td><td>#{_(self.status_type)}</td></tr>"
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
      res << "<tr><th>#{_('Description')}</th><td class=\"tip_description\">#{self.description_wrapped.gsub(/\n/, '<br/>').gsub(/\"/,'&quot;').gsub(/</,'&lt;').gsub(/>/,'&gt;')}</td></tr>" unless self.description.blank?
      res << "</table>"
      @tip = res.gsub(/\"/,'&quot;')
    end 
    @tip
  end

  def description_wrapped
    unless description.blank?
      self.description.chars.gsub(/(.{1,80})( +|$)\n?|(.{80})/, "\\1\\3\n")[0..1024]
    else
      nil
    end
  end 

  def css_classes
    unless @css
      @css = case self.status
      when 0 then ""
      when 1 then " in_progress"
      when 2 then " closed"
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

  def order_default
    [-(self.severity_id + self.priority), self.due_date.to_i, self.milestone ? 1 : 0, self.milestone_id.to_i > 0 ? self.milestone.name : ""]
  end 

  def order_date
    [self.created_at.to_i]
  end 

  def icon(icon_type = nil)
    icon_type ||= type_id
    case icon_type
      when 0 then "<img src=\"/images/task_icons/task.png\" alt=\"#{_'Task'}\" title=\"#{_'Task'}\" class=\"tooltip\" />"
      when 1 then "<img src=\"/images/task_icons/new_feature.png\" alt=\"#{_'New Feature'}\" title=\"#{_'New Feature'}\" class=\"tooltip\" />"
      when 2 then "<img src=\"/images/task_icons/bug.png\" alt=\"#{_'Defect'}\" title=\"#{_'Defect'}\" class=\"tooltip\" />"
      when 3 then "<img src=\"/images/task_icons/change.png\" alt=\"#{_'Improvement'}\" title=\"#{_'Improvement'}\" class=\"tooltip\" />"
    end 
  end 

  def worked_and_duration_class
    if worked_minutes > duration
      "overtime"
    else 
      ""
    end 
  end 
end
