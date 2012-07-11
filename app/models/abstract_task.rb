# encoding: UTF-8
require "active_record_extensions"
# this is abstract class for Task and Template
class AbstractTask < ActiveRecord::Base
  set_table_name "tasks"
  OPEN=0
  CLOSED=1
  WILL_NOT_FIX=2
  INVALID=3
  DUPLICATE=4
  MAX_STATUS=4

  belongs_to    :company
  belongs_to    :project
  belongs_to    :milestone

  has_many      :users, :through => :task_users, :source => :user
  has_many      :owners, :through =>:task_owners, :source=>:user
  has_many      :watchers, :through =>:task_watchers, :source=>:user

  #task_watcher and task_owner is subclasses of task_user
  has_many      :task_users, :dependent => :destroy, :foreign_key=>'task_id'
  has_many      :task_watchers, :dependent => :destroy, :foreign_key=>'task_id'
  has_many      :task_owners, :dependent => :destroy, :foreign_key=>'task_id'


  has_and_belongs_to_many  :dependencies, :class_name => "AbstractTask", :join_table => "dependencies", :association_foreign_key => "dependency_id", :foreign_key => "task_id", :order => 'dependency_id', :select => "tasks.*"
  has_and_belongs_to_many  :dependants, :class_name => "AbstractTask", :join_table => "dependencies", :association_foreign_key => "task_id", :foreign_key => "dependency_id", :order => 'task_id', :select=> "tasks.*"

  has_many      :attachments, :class_name => "ProjectFile", :dependent => :destroy, :foreign_key=>'task_id'
  has_many      :scm_changesets, :dependent =>:destroy, :foreign_key=>'task_id', :conditions => "task_id IS NOT NULL"

  belongs_to    :creator, :class_name => "User", :foreign_key => "creator_id"
  belongs_to    :old_owner, :class_name => "User", :foreign_key => "user_id"

  has_and_belongs_to_many  :tags, :join_table => 'task_tags', :foreign_key=>'task_id'

  has_many :task_property_values, :dependent => :destroy, :include => [ :property ], :foreign_key=>'task_id'
  accepts_nested_attributes_for :task_property_values, :allow_destroy => true

  has_many :task_customers, :dependent => :destroy, :foreign_key=>'task_id'
  has_many :customers, :through => :task_customers, :order => "customers.name asc"
  adds_and_removes_using_params :customers

  has_many      :todos, :order => "completed_at IS NULL desc, completed_at desc, position", :dependent => :destroy,  :foreign_key=>'task_id'
  accepts_nested_attributes_for :todos

  has_and_belongs_to_many :resources, :join_table=> 'resources_tasks', :foreign_key=>'task_id'

  has_many      :work_logs, :dependent => :destroy, :order => "started_at asc", :foreign_key=>'task_id'
  has_many      :event_logs, :as => :target

  has_many      :sheets,  :foreign_key=>'task_id'
  has_one       :ical_entry, :foreign_key=>'task_id'

  has_and_belongs_to_many :email_addresses, :join_table => 'email_address_tasks', :foreign_key=>'task_id'

  validates_length_of           :name,  :maximum=>200, :allow_nil => true
  validates_presence_of         :name

  validates_presence_of   :company
  validates_presence_of   :project_id
  validate :validate_properties

  before_create lambda { self.task_num = nil }
  after_create :set_task_num
  default_scope where("tasks.type != ?", "Template")

  scope :open_only, where("tasks.status = 0")
  scope :not_snoozed, where("wait_for_customer = ? AND hide_until IS ?", 0, nil)

  def self.accessed_by(user)
    readonly(false).joins(
      "join projects on
        tasks.project_id = projects.id
       join project_permissions on
        project_permissions.project_id = projects.id
      join users on
        project_permissions.user_id = users.id"
    ).where(
      "projects.completed_at IS NULL and
      users.id = ? and
      (
        project_permissions.can_see_unwatched = ? or
        users.id in
          (select task_users.user_id from task_users where task_users.task_id=tasks.id)
      )",
      user.id,
      true
    )
  end

  def self.all_accessed_by(user)
    readonly(false).joins(
      "join project_permissions on
        project_permissions.project_id = tasks.project_id
      join users as project_permission_users on
        project_permissions.user_id = project_permission_users.id"
    ).where(
      "project_permission_users.id= ? and
      (
        project_permissions.can_see_unwatched = ? or
        project_permission_users.id in
          (select task_users.user_id from task_users where task_users.task_id=tasks.id)
      )",
      user.id,
      true
    )
  end

  #let children redefine read statuses
  def set_task_read(user, status=true); end
  def unread?(user); end

  def has_milestone?
    self.milestone_id != nil and self.milestone_id != 0
  end

  def escape_twice(attr)
    h(String.new(h(attr)))
  end

  def to_tip(options = { })
    unless @tip
      owners = "No one"
      owners = self.users.collect{|u| u.name}.join(', ') unless self.users.empty?

      res = "<table id=\"task_tooltip\" cellpadding=0 cellspacing=0>"
      res << "<tr><th>#{_('Summary')}</td><td>#{escape_twice(self.name)}</tr>"
      res << "<tr><th>#{_('Project')}</td><td>#{escape_twice(self.project.full_name)}</td></tr>"
      res << "<tr><th>#{_('Tags')}</td><td>#{escape_twice(self.full_tags_without_links)}</td></tr>" unless self.full_tags_without_links.blank?
      res << "<tr><th>#{_('Assigned To')}</td><td>#{escape_twice(owners)}</td></tr>"
      res << "<tr><th>#{_('Resolution')}</td><td>#{_(self.status_type)}</td></tr>"
      res << "<tr><th>#{_('Milestone')}</td><td>#{escape_twice(self.milestone.name)}</td></tr>" if self.milestone_id.to_i > 0
      res << "<tr><th>#{_('Completed')}</td><td>#{options[:user].tz.utc_to_local(self.completed_at).strftime_localized(options[:user].date_format)}</td></tr>" if self.completed_at
      res << "<tr><th>#{_('Due Date')}</td><td>#{options[:user].tz.utc_to_local(due).strftime_localized(options[:user].date_format)}</td></tr>" if self.due
      unless self.dependencies.empty?
        res << "<tr><th valign=\"top\">#{_('Dependencies')}</td><td>#{self.dependencies.collect { |t| escape_twice(t.issue_name) }.join('<br />')}</td></tr>"
      end
      unless self.dependants.empty?
        res << "<tr><th valign=\"top\">#{_('Depended on by')}</td><td>#{self.dependants.collect { |t| escape_twice(t.issue_name) }.join('<br />')}</td></tr>"
      end
      res << "<tr><th>#{_('Progress')}</td><td>#{TimeParser.format_duration(self.worked_minutes, options[:duration_format], options[:workday_duration], options[:days_per_week])} / #{TimeParser.format_duration( self.duration.to_i, options[:duration_format], options[:workday_duration], options[:days_per_week] )}</tr>"
      res << "<tr><th>#{_('Description')}</th><td class=\"tip_description\">#{escape_twice(self.description_wrapped).gsub(/\n/, '<br/>').gsub(/\"/,'&quot;')}</td></tr>" unless self.description.blank?
      res << "</table>"
      @tip = res.gsub(/\"/,'&quot;')
    end
    @tip
  end

  def resolved?
    status != 0
  end

  # define open?, closed?, will_not_fix?, invalid?, duplicate? predicates
  ['OPEN', 'CLOSED', 'WILL_NOT_FIX', 'INVALID', 'DUPLICATE'].each do |status_name|
    define_method(status_name.downcase + '?') { status == self.class.const_get(status_name) }
  end

  def done?
    self.resolved? && self.completed_at != nil
  end

  def overdue?
    self.due_date ? (self.due_date.to_time <= Time.now.utc) : false
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

  def target_date
    due_at || milestone.try(:due_at)
  end

  alias_method :due_date, :target_date
  alias_method :due, :due_date

  def full_name
    if self.project
      [ERB::Util.h(self.project.full_name), full_tags].join(' / ').html_safe
    else
      ""
    end
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

  def self.status_types
    Company.first.statuses.all.collect {|a| a.name }
  end

  def owners_to_display
    o = self.owners.collect{ |u| u.name}.join(', ')
    o = "Unassigned" if o.nil? || o == ""
    o
  end

  def set_tags=( tagstring )
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

  def to_s
    self.name
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

  # Sets up custom properties using the given form params
  def properties=(params)
    ids=[]
    attributes= params.collect {  |prop_id, val_id|
      # task_property_values may be changed elsewhere
      # discards the cached copy of task_property_values
      # reload from the database to avoid duplicate insert conflicts
      task_property_value= task_property_values(true).find_by_property_id(prop_id)
      if task_property_value.nil?
        hash = { :property_id => prop_id, :property_value_id => val_id }
      else
        ids << task_property_value.id
        hash = { :id => task_property_value.id }
        if val_id.blank?
          hash[:_destroy] = 1
        else
          hash[:property_id] = prop_id
          hash[:property_value_id] = val_id
        end
      end
      hash
    }
    attributes += (self.task_property_values.collect(&:id) - ids).collect{ |id| { :id=>id, :_destroy=>1 } }
    self.task_property_values_attributes = attributes
  end

  #set default properties for new task
  def set_default_properties
    task_property_values.clear
    self.company.properties.each do |property|
      task_property_values.build(:property_id=>property.id, :property_value_id=> property.default_value.id) unless property.default_value.nil?
    end
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

  def set_users_dependencies_resources(params, current_user)
    set_users(params)
    set_dependency_attributes(params[:dependencies], current_user)
    set_resource_attributes(params[:resource])
    self.attachments.find(params[:delete_files]).each{ |file| file.destroy }  rescue nil
    self.updated_by_id = current_user.email_addresses.first.id
    self.creator_id = current_user.id if creator_id.nil?
  end
  ###
  # Custom validation for tasks.
  ###
  def validate_properties
    res = true

    mandatory_properties = company.properties.select { |p| p.mandatory? }
    mandatory_properties.each do |p|
      if !property_value(p)
        res = false
        errors.add(:base, _("%s is required", p.name))
      end
    end

    return res
  end

  def create_attachments(files_array, current_user)
    attachments =
      if files_array.blank? || files_array.reject(&:blank?).empty?
        []
      else
        files_array.map do |tmp_file|
          next if tmp_file.is_a?(String)
          normalize_filename(tmp_file)
          add_attachment(tmp_file, current_user)
        end.compact
      end

    attachments
  end

  def add_attachment(file, user)
    uri = Digest::MD5.hexdigest(file.read)
    if self.attachments.where(:uri => uri).count == 0
      self.attachments.create(
        :company => self.company,
        :customer => self.project.customer,
        :project => self.project,
        :user => user,
        :file => file,
        :uri  => uri
    )
    end
  end

  def statuses_for_select_list
    company.statuses.collect{|s| [s.name]}.each_with_index{|s,i| s<< i }
  end

  def notify_emails
    email_addresses.map{ |ea| ea.email}.join(', ')
  end

  def notify_emails=(emails)
    email_addresses.clear
    (emails || "").split(/$| |,/).map{ |email| email.strip.empty? ? nil : email.strip }.compact.each{ |email|
      ea= EmailAddress.find_or_create_by_email(email)
      self.email_addresses<< ea
    }
  end

  def notify_emails_array
    email_addresses.map{ |ea| ea.email }
  end

  def task_due_calculation(due_at, user)
    begin
      # Only care about the date part, parse the input date string into DateTime in UTC.
      # Later, the date part will be converted from DateTime to string display in UTC, so that it doesn't change.
      format = "#{user.date_format}"
      due_date = DateTime.strptime(due_at, format).ago(-12.hours)
    rescue
    end
    self.due_at = due_date unless due_date.nil?
  end

  # log task changes, worktimes, comments and update task
  def self.update(task, params, user)
    old_tags = task.tags.collect {|t| t.name}.sort.join(', ')
    old_deps = task.dependencies.collect { |t| "[#{t.issue_num}] #{t.name}" }.sort.join(', ')
    old_users = task.owners.collect{ |u| u.id}.sort.join(',')
    old_users ||= "0"
    old_project_id = task.project_id
    old_project_name = task.project.name
    old_task = task.dup

    task.send(:do_update, params, user)

    # event_log stores task property changes
    event_log = EventLog.new(:event_type => EventLog::TASK_MODIFIED, :user => user, :company => user.company, :project => task.project)

    body = ""
    body << ((old_task[:name] != task[:name]) ? ("- Name:".html_safe  + "#{old_task[:name]} " + "->".html_safe + " #{task[:name]}\n") : "")
    body << ((old_task.description != task.description) ? "- Description changed\n".html_safe : "")

    assigned_ids = (params[:assigned] || [])
    assigned_ids = assigned_ids.uniq.collect { |u| u.to_i }.sort.join(',')
    if old_users != assigned_ids
      task.users.reload
      new_name = task.owners.empty? ? 'Unassigned' : task.owners.collect{ |u| u.name}.join(', ')
      body << "- Assignment: #{new_name}\n"
      event_log.event_type = EventLog::TASK_ASSIGNED
    end

    if old_project_id != task.project_id
      body << "- Project: #{old_project_name} -> #{task.project.name}\n"
      WorkLog.update_all("customer_id = #{task.project.customer_id}, project_id = #{task.project_id}", "task_id = #{task.id}")
      ProjectFile.update_all("customer_id = #{task.project.customer_id}, project_id = #{task.project_id}", "task_id = #{task.id}")
    end

    old_duration = TimeParser.format_duration(old_task.duration, user.duration_format, user.workday_duration, user.days_per_week)
    new_duration = TimeParser.format_duration(task.duration, user.duration_format, user.workday_duration, user.days_per_week)

    body << ((old_task.duration != task.duration) ? "- Estimate: #{old_duration} -> #{new_duration}\n".html_safe : "")

    if old_task.milestone != task.milestone
      old_name = "None"
      unless old_task.milestone.nil?
        old_name = old_task.milestone.name
        old_task.milestone.update_counts
      end

      new_name = "None"
      new_name = task.milestone.name unless task.milestone.nil?
      body << "- Milestone: #{old_name} -> #{new_name}\n"
    end

    if old_task.due_at != task.due_at
      old_name = new_name = "None"
      old_name = user.tz.utc_to_local(old_task.due_at).strftime_localized("%A, %d %B %Y") unless old_task.due_at.nil?
      new_name = user.tz.utc_to_local(task.due_at).strftime_localized("%A, %d %B %Y") unless task.due_at.nil?

      body << "- Due: #{old_name} -> #{new_name}\n".html_safe
    end

    new_tags = task.tags.collect {|t| t.name}.sort.join(', ')
    if old_tags != new_tags
      body << "- Tags: #{new_tags}\n"
    end

    new_deps = task.dependencies.collect { |t| "[#{t.issue_num}] #{t.name}"}.sort.join(", ")
    if old_deps != new_deps
       body << "- Dependencies: #{(new_deps.length > 0) ? new_deps : _("None")}"
    end

    if old_task.status != task.status
      body << "- Resolution: #{old_task.status_type} -> #{task.status_type}\n"

      if( task.resolved? && old_task.status != task.status )
        event_log.event_type = EventLog::TASK_MODIFIED
      end

      if( task.completed_at && old_task.completed_at.nil?)
        event_log.event_type = EventLog::TASK_COMPLETED
      end

      if( !task.resolved? && old_task.resolved? )
        event_log.event_type = EventLog::TASK_REVERTED
      end
    end

    files = task.create_attachments(params['tmp_files'], user)
    files.each do |file|
      body << "- Attached: #{file.file_file_name}\n"
    end
    event_log.body = body
    event_log.target = task
    event_log.save! unless event_log.body.blank?

    # work_log stores worktime & comment
    work_log = WorkLog.build_work_added_or_comment(task, user, params)
    if work_log
      work_log.event_log.event_type = event_log.event_type unless event_log.body.blank?
      work_log.save!
      work_log.notify(files) if work_log.comment?
    end
  end

private

  def full_tags
    self.tags.collect{ |t| "<a href=\"/tasks?tag=#{ERB::Util.h t.name}\" class=\"description\">#{ERB::Util.h t.name.capitalize.gsub(/\"/,'&quot;'.html_safe)}</a>" }.join(" / ").html_safe
  end

  def set_task_num
    AbstractTask.transaction do
      max = "SELECT * FROM (SELECT 1 + coalesce((SELECT max(task_num) FROM tasks WHERE company_id ='#{self.company_id}'), 0)) AS max"
      connection.execute("UPDATE tasks set task_num = (#{max}) where id = #{self.id}")
    end
    self.reload
  end

  ###
  # Sets the owners/watchers of this task from ids.
  # Existing records WILL  be cleared by this method.
  ###
  def set_user_ids(relation, ids)
    return if ids.nil?

    relation.destroy_all

    ids.each do |o|
      next if o.to_i == 0
      u = company.users.find(o.to_i)
      relation.create(:user => u, :task => self)
    end
  end

  ###
  # Sets up any task owners or watchers from the given params.
  # Any existings ones not in the given params will be removed.
  ###
  def set_users(params)
    all_users = params[:users] || []
    owners = params[:assigned] || []
    emails = params[:unknowns] || []
    watchers = all_users - owners
    set_user_ids(self.task_owners, owners)
    set_user_ids(self.task_watchers, watchers)
    self.notify_emails = emails.join(',')
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
        t = self.class.accessed_by(user).find_by_task_num(dep)
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

  def normalize_filename(file)
    file.original_filename.gsub!(' ', '_')
    file.original_filename.gsub!(/[^a-zA-Z0-9_\.]/, '')
  end

  # update task from params
  def do_update(params, user)
    if self.wait_for_customer and !params[:comment].blank?
      self.wait_for_customer = false
      params[:task].delete(:wait_for_customer)
    end

    self.attributes = params[:task]

    if self.service_id == -1
      self.isQuoted = true
      self.service_id = nil
    else
      self.isQuoted = false
    end

    self.task_due_calculation(params, self)
    self.duration = TimeParser.parse_time(user, params[:task][:duration], true) if (params[:task] && params[:task][:duration])

    if self.resolved? && self.completed_at.nil?
      self.completed_at = Time.now.utc
    end

    if !self.resolved? && !self.completed_at.nil?
      self.completed_at = nil
    end

    self.scheduled_duration = self.duration if self.scheduled?
    self.scheduled_at = self.due_at if self.scheduled?
    self.set_users_dependencies_resources(params, user)

    self.save!

    self
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
#  creator_id         :integer(4)
#  hide_until         :datetime
#  scheduled_at       :datetime
#  scheduled_duration :integer(4)
#  scheduled          :boolean(1)      default(FALSE)
#  worked_minutes     :integer(4)      default(0)
#  type               :string(255)     default("Task")
#  weight             :integer(4)      default(0)
#  weight_adjustment  :integer(4)      default(0)
#  wait_for_customer  :boolean(1)      default(FALSE)
#  estimate           :decimal(5, 2)
#
# Indexes
#
#  index_tasks_on_type_and_task_num_and_company_id  (type,task_num,company_id) UNIQUE
#  tasks_company_id_index                           (company_id)
#  tasks_due_at_idx                                 (due_at)
#  index_tasks_on_milestone_id                      (milestone_id)
#  tasks_project_completed_index                    (project_id,completed_at)
#  tasks_project_id_index                           (project_id,milestone_id)
#

