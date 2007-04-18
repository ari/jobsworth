class Task < ActiveRecord::Base

  include Misc

  acts_as_ferret :fields => { 'company_id' => {},
    'project_id' => {},
    'full_name' => { :boost => 1.5 },
    'name' => { :boost => 2.0 },
    'issue_name' => { :boost => 0.8 },
    'description' => { :boost => 1.7}
  }

  belongs_to    :company
  belongs_to    :project
  belongs_to    :milestone
  has_many      :users, :through => :task_owners, :source => :user
  has_many      :task_owners, :dependent => :destroy

  has_many      :work_logs, :dependent => :destroy
  has_many      :attachments, :class_name => "ProjectFile", :dependent => :destroy

  has_many      :notifications, :dependent => :destroy
  has_many      :watchers, :through => :notifications, :source => :user


  belongs_to    :creator, :class_name => "User"

  belongs_to     :old_owner, :class_name => "User", :foreign_key => "user_id"

  has_and_belongs_to_many      :tags, :join_table => :task_tags

  validates_length_of           :name,  :maximum=>200
  validates_presence_of         :name


  def done?
    res = 0
    if self.status > 1
      res = 1
    end
  end

  def done
    res = 0
    if self.status > 1
      res = 1
    end
  end

  def set_task_num(company_id)
    self.task_num = Task.maximum('task_num', :conditions => ["company_id = ?", company_id]) + 1 rescue self.task_num = 1
  end

  def time_left
    res = 0
    if self.due_at != nil
      res = self.due_at - Time.now.utc
    end
  end

  def overdue?
    res = 0
    if self.due_at != nil
      if self.due_at <= Time.now.utc
        res = 1
      end
    end
  end

  def worked_minutes
    @minutes ||= 0
    return @minutes if @minutes > 0
    self.work_logs.each do | work |
        @minutes += work.duration
    end
    @minutes
  end

  def full_name
    @full_name ||= [self.project.full_name, self.full_tags].join(' / ')
  end

  def full_tags
    @full_tags ||= self.tags.collect{ |t| t.name.capitalize }.join(" / ")
  end

  def issue_name
    @issue_name ||= "[##{self.task_num}] #{self[:name]}"
  end

  def issue_num
    if self.status > 1
    "<strike>##{self.task_num}</strike>"
    else
    "##{self.task_num}"
    end
  end

  def name
    "#{self[:name]}"
  end

  def status_name
    "#{self.issue_num} #{self.name}"
  end

  def issue_type
    case self.type_id
      when 0 then "Task"
      when 1 then "New Feature"
      when 2 then "Defect"
      when 3 then "Improvement"
    end

  end

  def status_type
    case self.status
      when 0 then "Open"
      when 1 then "In Progress"
      when 2 then "Closed"
      when 3 then "Won't fix"
      when 4 then "Invalid"
      when 5 then "Duplicate"
    end
  end

  def priority_type
    case self.priority
      when -2 then "Lowest"
      when -1 then "Low"
      when 0 then "Normal"
      when 1 then "High"
      when 2 then "Urgent"
      when 3 then "Critical"
    end
  end

  def severity_type
    case self.severity_id
      when -2 then "Trivial"
      when -1 then "Minor"
      when 0 then "Normal"
      when 1 then "Major"
      when 2 then "Critical"
      when 3 then "Blocker"
    end
  end

  def set_tags( tagstring )
    self.tags.clear
    tagstring.split(',').each do |t|
      tag = Tag.new
      tag.company_id = self.company_id
      tag.name = t.downcase.strip

      if tag.name.length == 0
        next
      end

      unless tag.exists?
        tag.save
      else
        tag = Tag.find(:first, :conditions => ["company_id = ? AND name = ?", tag.company_id, tag.name])
      end
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
    groups = {}
    num_matching = 0

    #print "[#{depth}]Tags: #{done_tags.join(' / ')} | #{tags.join(' / ')}\n"

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
      [tasks,groups]
    elsif groups.keys.size > 0
      [groups]
    else
      [tasks]
    end
  end

  def Task.tag_groups(company_id, tags, tasks)

    groups = Task.group_by_tags(tasks,tags,[], 0)

    groups
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
    sql << " (AND tasks.milestone_id NOT IN (#{completed_milestones_ids}) OR tasks.milestone_id IS NULL)" if completed_milestones_ids != ''
    sql << " AND projects.customer_id = #{options[:filter_customer]}" if options[:filter_customer].to_i > 0
    sql << " GROUP BY tasks.id"
    sql << " HAVING COUNT(tasks.id) = #{tags.size}"
    sql << " ORDER BY tasks.completed_at is NOT NULL, tasks.completed_at desc, tasks.priority + tasks.severity_id desc, CASE WHEN (tasks.due_at IS NULL AND milestones.due_at IS NULL) THEN 1 ELSE 0 END, CASE WHEN (tasks.due_at IS NULL AND tasks.milestone_id IS NOT NULL) THEN milestones.due_at ELSE tasks.due_at END, tasks.completed_at DESC, tasks.name"

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

  def to_tip(options = { })
    owners = "No one"
    owners = self.users.collect{|u| u.name}.join(', ') unless self.users.empty?
    res = ""
    res << "<strong>#{_('Summary')}</strong> #{self.name}<br/>"
    res << "<strong>#{_('Project')}</strong> #{self.project.full_name}<br/>"
    res << "<strong>#{_('Tags')}</strong> #{self.full_tags}<br/>"
    res << "<strong>#{_('Assigned To')}</strong> #{owners}<br/>"
    res << "<strong>#{_('Status')}</strong> #{self.status_type}<br/>"
    res << "<strong>#{_('Progress')}</strong> #{format_duration(self.worked_minutes, options[:duration_format])} / #{format_duration( self.duration, options[:duration_format] )}"
    res << "<div class=tip_description> #{self.description.gsub(/\n/, '<br/>').gsub(/\"/,'&quot;')}</div>" if( self.description && self.description.strip.length > 0)
    res.gsub(/\"/,'&quot;')
  end
end
