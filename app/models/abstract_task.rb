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
  include Misc

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
  has_many      :scm_changesets, :dependent =>:destroy, :foreign_key=>'task_id'

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

  has_many      :sheets,  :foreign_key=>'task_id'
  has_one       :ical_entry, :foreign_key=>'task_id'

  has_and_belongs_to_many :email_addresses, :join_table => 'email_address_tasks', :foreign_key=>'task_id'

  validates_length_of           :name,  :maximum=>200, :allow_nil => true
  validates_presence_of         :name

  validates_presence_of   :company
  validates_presence_of   :project_id
  validate :validate_properties

  before_create :set_task_num

  def self.default_scope
    where("tasks.type != ?", "Template")
  end

  scope :opened, where("tasks.status = 0")
  scope :not_snoozed, where("wait_for_customer = ? AND hide_until IS ?", 0, nil)

  def self.accessed_by(user)
    readonly(false).joins("join projects on tasks.project_id = projects.id join project_permissions on project_permissions.project_id = projects.id join users on project_permissions.user_id = users.id").where("projects.completed_at IS NULL and users.id=? and (project_permissions.can_see_unwatched = ? or users.id in(select task_users.user_id from task_users where task_users.task_id=tasks.id))", user.id, true)
  end
  def self.all_accessed_by(user)
    readonly(false).joins("join project_permissions on project_permissions.project_id = tasks.project_id join users on project_permissions.user_id = users.id").where("users.id=? and (project_permissions.can_see_unwatched = ? or users.id in(select task_users.user_id from task_users where task_users.task_id=tasks.id))", user.id, true)
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
      res << "<tr><th>#{_('Requested By')}</td><td>#{escape_twice(self.requested_by)}</td></tr>" unless self.requested_by.blank?
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
      res << "<tr><th>#{_('Progress')}</td><td>#{format_duration(self.worked_minutes, options[:duration_format], options[:workday_duration], options[:days_per_week])} / #{format_duration( self.duration.to_i, options[:duration_format], options[:workday_duration], options[:days_per_week] )}</tr>"
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

  def create_attachments(params, current_user)
    unless params['tmp_files'].blank? || params['tmp_files'].select{|f| f != ""}.size == 0
      return params['tmp_files'].map do |tmp_file|
        next if tmp_file.is_a?(String)
        normalize_filename(tmp_file)
        add_attachment(tmp_file, current_user)
      end.compact
    end
    return []
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
private

  def full_tags
    self.tags.collect{ |t| "<a href=\"/tasks/list/?tag=#{ERB::Util.h t.name}\" class=\"description\">#{ERB::Util.h t.name.capitalize.gsub(/\"/,'&quot;'.html_safe)}</a>" }.join(" / ").html_safe
  end

  def set_task_num
    @attributes['task_num'] = self.class.where("company_id = ?", company.id).maximum('task_num').to_i + 1
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
    watchers = all_users - owners
    set_user_ids(self.task_owners, owners)
    set_user_ids(self.task_watchers, watchers)
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
#  hide_until         :datetime
#  scheduled_at       :datetime
#  scheduled_duration :integer(4)
#  scheduled          :boolean(1)      default(FALSE)
#  worked_minutes     :integer(4)      default(0)
#  type               :string(255)     default("Task")
#  weight             :integer(4)      default(0)
#  weight_adjustment  :integer(4)      default(0)
#  wait_for_customer  :boolean(1)      default(FALSE)
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

