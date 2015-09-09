# encoding: UTF-8
# A user from a company
require 'digest/md5'

class User < ActiveRecord::Base
  # Include default devise modules. Others available are:
  # :token_authenticatable, :confirmable, :lockable and :timeoutable
  devise :database_authenticatable, :registerable, :encryptable,
         :recoverable, :rememberable, :trackable

  # Setup accessible (or protected) attributes for your model
  ACCESS_CONTROL_ATTRIBUTES=[:create_projects, :use_resources, :read_clients, :create_clients, :edit_clients, :can_approve_work_logs, :admin, :access_level_id]
  attr_protected :uuid, :autologin, *ACCESS_CONTROL_ATTRIBUTES, :company_id, :encrypted_password, :password_salt, :reset_password_token, :remember_token, :remember_created_at, :reset_password_sent_at

  has_many(:custom_attribute_values, :as => :attributable, :dependent => :destroy,
           # set validate = false because validate method is over-ridden and does that for us
           :validate => false)
  include CustomAttributeMethods

  belongs_to    :company
  belongs_to    :customer
  belongs_to    :access_level
  belongs_to    :default_project_users
  has_many      :projects, :through => :project_permissions, :source=>:project, :conditions => ['projects.completed_at IS NULL'], :order => "projects.customer_id, projects.name", :readonly => false
  has_many      :completed_projects, :through => :project_permissions, :conditions => ['projects.completed_at IS NOT NULL'], :source => :project, :order => "projects.customer_id, projects.name", :readonly => false
  has_many      :all_projects, :through => :project_permissions, :order => "projects.customer_id, projects.name", :source => :project, :readonly => false
  has_many      :project_permissions, :dependent => :destroy

  has_many      :tasks, :through => :task_owners, :class_name => "TaskRecord"
  has_many      :task_owners, :dependent => :destroy
  has_many      :work_logs

  has_many      :notifications, :class_name=>"TaskWatcher", :dependent => :destroy
  has_many      :notifies, :through => :notifications, :source => :task

  has_many      :widgets, :order => "widgets.column, widgets.position", :dependent => :destroy

  has_many      :task_filters, :dependent => :destroy
  has_many      :visible_task_filters, :source => "task_filter", :through => :task_filter_users, :order => "task_filters.name"
  has_many      :task_filter_users, :dependent => :delete_all

  has_many      :sheets, :dependent => :destroy

  has_many      :preferences, :as => :preferencable
  has_many      :email_addresses, :dependent => :destroy, :order => "email_addresses.default DESC"

  has_many      :email_deliveries

  has_one       :work_plan, :dependent => :destroy

  has_attached_file :avatar, :whiny => false , :styles=>{ :small=> "25x25>", :large=>"50x50>"}, :path => File.join(Setting.store_root, ":company_id", 'avatars', ":id_:basename_:style.:extension")

  Paperclip.interpolates :company_id do |attachment, style|
    attachment.instance.company_id
  end

  accepts_nested_attributes_for :work_plan

  include PreferenceMethods

  validates_length_of :name,  :maximum=>200, :allow_nil => true
  validates_presence_of :name

  validates :username,
            :presence => true,
            :length => {:minimum => 2, :maximum => 200},
            :uniqueness => { :case_sensitive => false, :scope => "company_id" }

  validates :password, :confirmation => true, :if => :password_required?
  validates_presence_of :email


  validates_presence_of :company
  validates :date_format, :presence => true, :inclusion => {:in => %w(%m/%d/%Y %d/%m/%Y %Y-%m-%d)}
  validates :time_format, :presence => true, :inclusion => {:in => %w(%H:%M %I:%M%p)}
  validate :validate_custom_attributes

  before_create     :generate_uuid
  after_create      :generate_widgets
  before_create     :set_default_values
  before_validation :set_date_time_formats, :on => :create
  before_destroy    :reject_destroy_if_exist
  after_create      :update_orphaned_email_addresses

  scope :active, where(:active => true)
  scope :auto_add, active.where(:auto_add_to_customer_tasks => true)
  scope :by_email, lambda{ |email|
    where('email_addresses.email' => email, 'email_addresses.default' => true).joins(:email_addresses).readonly(false)
  }
  scope :from_this_year, where("created_at > ?", Time.zone.now.beginning_of_year - 1.month)
  scope :recent_users, limit(50).order("created_at desc")

  ###
  # Searches the users for company and returns
  # any that have names or ids that match at least one of
  # the given strings
  ###
  def self.search(company, strings)
    conds = Search.search_conditions_for(strings, [ :name ], :start_search_only => true)
    return company.users.where(conds)
  end

  def self.search_by_name(term)
    name = arel_table[:name]
    where(name.matches("#{term}%").or(name.matches("%#{term}%"))).order('name')
  end

  def has_projects?
    projects.any?
  end

  def set_access_control_attributes(params)
    ACCESS_CONTROL_ATTRIBUTES.each do |attr|
      next if params[attr].nil?
      self.send(attr.to_s + '=', params[attr])
    end
  end

  def avatar_path
    avatar.path(:small)
  end

  def avatar_large_path
    avatar.path(:large)
  end

  def avatar?
    !self.avatar_path.nil? and File.exist?(self.avatar_path)
  end

  def set_default_values
    self.work_plan ||= WorkPlan.new(:monday => 8, :tuesday => 8, :wednesday => 8, :thursday => 8, :friday => 8, :saturday => 0, :sunday => 0)
    self.time_zone ||= "Australia/Sydney"
    self.date_format ||= "%d/%m/%Y"
    self.time_format ||= "%H:%M"
    self.locale ||=  "en_US"
  end

  def generate_uuid
    self.uuid ||= Digest::MD5.hexdigest( rand(100000000).to_s + Time.now.to_s)
    self.autologin ||= Digest::MD5.hexdigest( rand(100000000).to_s + Time.now.to_s)
  end

  def new_widget
    Widget.new(:user => self, :company_id => self.company_id, :collapsed => 0, :configured => true)
  end

  def generate_widgets
    w = new_widget
    w.name = I18n.t("widgets.top_tasks")
    w.widget_type = 0
    w.number = 5
    w.mine = true
    w.order_by = "priority"
    w.column = 0
    w.position = 0
    w.save

    w = new_widget
    w.name = I18n.t("widgets.newest_tasks")
    w.widget_type = 0
    w.number = 5
    w.mine = false
    w.order_by = "date"
    w.column = 0
    w.position = 1
    w.save

    w = new_widget
    w.name = I18n.t("widgets.open_tasks")
    w.widget_type = 3
    w.number = 7
    w.mine = true
    w.column = 1
    w.position = 0
    w.save
  end

  def avatar_url(size=32, secure = false)
    if avatar?
      if size > 25 && File.exist?(avatar_large_path)
        '/users/avatar/'+id.to_s+'?large=1'
      else
        '/users/avatar/'+id.to_s
      end
    elsif email
      if secure
  "https://secure.gravatar.com/avatar.php?gravatar_id=#{Digest::MD5.hexdigest(self.email.downcase)}&rating=PG&size=#{size}"
      else
  "http://www.gravatar.com/avatar.php?gravatar_id=#{Digest::MD5.hexdigest(self.email.downcase)}&rating=PG&size=#{size}"
      end
    end
  end

  # label and value are used for the json formatting used for autocomplete
  def label
    name
  end
  alias_method :value, :label
  alias_method :display_name, :label

  def display_login
    name + " / " + (customer.nil? ? company.name : customer.name)
  end

  def can?(project, perm)
    return true if project.nil? or admin?

    @perm_cache ||= {}
    unless @perm_cache[project.id]
      @perm_cache[project.id] ||= {}
      self.project_permissions.each do | p |
        @perm_cache[p.project_id] ||= {}
        ProjectPermission.permissions.each do |p_perm|
          @perm_cache[p.project_id][p_perm] = p.can?(p_perm)
        end
      end
    end

    (@perm_cache[project.id][perm] || false)
  end

  def can_all?(projects, perm)
    projects.all? {|p| can?(p, perm)}
  end

  def can_any?(project, perm)
    projects.any? {|p| can?(p, perm)}
  end

  def admin?
    !self.admin.nil? && self.admin > 0
  end


  def can_use_billing?
    company.use_billing
  end

  ###
  # Returns true if this user is allowed to view the clients section
  # of the website.
  ###
  def can_view_clients?
    self.admin? or self.read_clients?
  end

  # Returns true if this user is allowed to view the given task.
  def can_view_task?(task)
    ! TaskRecord.accessed_by(self).find_by_id(task).nil?
  end

  # Returns a fragment of sql to restrict tasks to only the ones this
  # user can see
  def user_tasks_sql
    res = []
    if self.projects.any?
      res << "tasks.project_id in (#{ all_project_ids.join(",") })"
    end

    res << "task_users.user_id = #{ self.id }"

    res = res.join(" or ")
    return "(#{ res })"
  end

 # Returns an array of all milestone this user has access to
  # (through projects).
  # If options is passed, those options will be passed to the find.
  def milestones
    company.milestones.where([ "projects.id in (?)", all_project_ids ]).includes(:project).order("lower(milestones.name)")
  end

  def tz
    @tz ||= TZInfo::Timezone.get(self.time_zone)
  end

  # Get date formatter in a form suitable for jQuery-UI
  def dateFormat
    return 'mm/dd/yy' if self.date_format == '%m/%d/%Y'
    return 'dd/mm/yy' if self.date_format == '%d/%m/%Y'
    return 'yy/mm/dd' if self.date_format == '%Y-%m-%d'
  end

  def to_s
    str = [ name ]
    str << "(#{ customer.name })" if customer

    str.join(" ")
  end

  def private_task_filters
    task_filters.visible.where("user_id = ?", self.id)
  end

  def shared_task_filters
    company.task_filters.shared.visible.where("user_id != ?", self.id)
  end

  # return as a string the default email address for this user
  # return nil if this user has no default email address
  def email
    email_addresses.detect { |ea| ea.default? }.try(:email)
  end

  alias_method :primary_email, :email

  def email=(new_email)
    ea = EmailAddress.where(:email => new_email).first || EmailAddress.new(:email => new_email, :company => self.company)
    if ea.user
      errors.add(:email, I18n.t("errors.messages.taken_by", email: ea.email, user: ea.user.name))
    else
      self.email_addresses.update_all(:default => false)
      ea.default = true
      self.email_addresses << ea
    end
  end

  def get_projects
    (admin?) ? company.projects : all_projects
  end

  # Get the next tasks for the nextTasks panel
  def next_tasks(count = 5)
    self.tasks.open_only.not_snoozed.order("tasks.weight DESC").limit(count)
  end

  def workday_length(date)
    (self.work_plan.send(self.tz.utc_to_local(date.utc).strftime("%A").downcase) * 60).to_i
  end

  def top_next_task
    next_tasks(1).first
  end

  def schedule_tasks(options={})
    options[:limit] ||= 1000000
    options[:save] = true unless options.key?(:save)

    if options[:save]
      self.update_column(:need_schedule, false)
    end

    acc_total = self.work_logs.where("started_at > ? AND started_at < ?", self.tz.local_to_utc(self.tz.now.beginning_of_day), self.tz.local_to_utc(self.tz.now.end_of_day)).sum(:duration)

    due_date_num = 0
    self.next_tasks(options[:limit]).each do |task|
      while acc_total >= self.workday_length(Time.now + due_date_num.days)
        acc_total -= self.workday_length(Time.now + due_date_num.days)
        due_date_num += 1
      end

      if options[:save]
        task.update_column(:estimate_date, Time.now + due_date_num.days)
      else
        task.estimate_date = Time.now + due_date_num.days
      end

      yield task if block_given?

      # show when the task begins, instead of the finish date
      acc_total += task.minutes_left
    end
  end

  def self.schedule_tasks
    User.where(:need_schedule => true).each do |user|
      user.schedule_tasks
    end
  end

  # +conditions+ is guaranteed by Devise to have +:subdomain+ and +:username+ keys
  def self.find_for_authentication(conditions={})
    company = Company.where(:subdomain => conditions.delete(:subdomain)).first
    return false if company.blank?
    super(conditions.merge :company_id => company.id)
  end

  def use_resources?
    use_resources && company.use_resources
  end

  protected

  def password_required?
    new_record? || !password.nil? || !password_confirmation.nil?
  end

private

  # This user may have been automatically linked to orphaned emails,
  # update work_logs and tasks that are used to be linked to the orphaned emails.
  def update_orphaned_email_addresses
    self.email_addresses.each do |ea|
      ea.link_to_user(self.id)
    end
  end

  def reject_destroy_if_exist
    [:work_logs].each do |association|
      errors.add(:base, I18n.t("errors.messages.reject_destroy_if_exist", association: association.to_s.humanize)) unless eval("#{association}.count").zero?
    end
    if errors.count.zero?
      ActiveRecord::Base.connection.execute("UPDATE tasks set creator_id = NULL WHERE company_id = #{self.company_id} AND creator_id = #{self.id}")
      return true
    else
      return false
    end
  end

  # Sets the date time format for this user to a sensible default
  # if it hasn't already been set
  def set_date_time_formats
    first_user = company.users.detect { |u| u != self }

    if first_user and first_user.time_format and first_user.date_format
      self.time_format = first_user.time_format
      self.date_format = first_user.date_format
    else
      self.date_format = "%d/%m/%Y"
      self.time_format = "%H:%M"
    end
  end
end


# == Schema Information
#
# Table name: users
#
#  id                         :integer(4)      not null, primary key
#  name                       :string(200)     default(""), not null
#  username                   :string(200)     default(""), not null
#  company_id                 :integer(4)      default(0), not null
#  created_at                 :datetime
#  updated_at                 :datetime
#  admin                      :integer(4)      default(0)
#  time_zone                  :string(255)
#  option_tracktime           :integer(4)
#  seen_news_id               :integer(4)      default(0)
#  last_project_id            :integer(4)
#  last_seen_at               :datetime
#  last_ping_at               :datetime
#  last_milestone_id          :integer(4)
#  last_filter                :integer(4)
#  date_format                :string(255)     default("%d/%m/%Y"), not null
#  time_format                :string(255)     default("%H:%M"), not null
#  receive_notifications      :integer(4)      default(1)
#  uuid                       :string(255)     not null
#  seen_welcome               :integer(4)      default(0)
#  locale                     :string(255)     default("en_US")
#  option_avatars             :integer(4)      default(1)
#  autologin                  :string(255)     not null
#  remember_until             :datetime
#  option_floating_chat       :boolean(1)      default(TRUE)
#  create_projects            :boolean(1)      default(TRUE)
#  receive_own_notifications  :boolean(1)      default(TRUE)
#  use_resources              :boolean(1)
#  customer_id                :integer(4)
#  active                     :boolean(1)      default(TRUE)
#  read_clients               :boolean(1)      default(FALSE)
#  create_clients             :boolean(1)      default(FALSE)
#  edit_clients               :boolean(1)      default(FALSE)
#  can_approve_work_logs      :boolean(1)
#  auto_add_to_customer_tasks :boolean(1)
#  access_level_id            :integer(4)      default(1)
#  avatar_file_name           :string(255)
#  avatar_content_type        :string(255)
#  avatar_file_size           :integer(4)
#  avatar_updated_at          :datetime
#  encrypted_password         :string(128)     default(""), not null
#  password_salt              :string(255)     default(""), not null
#  reset_password_token       :string(255)
#  remember_token             :string(255)
#  remember_created_at        :datetime
#  sign_in_count              :integer(4)      default(0)
#  current_sign_in_at         :datetime
#  last_sign_in_at            :datetime
#  current_sign_in_ip         :string(255)
#  last_sign_in_ip            :string(255)
#  reset_password_sent_at     :datetime
#
# Indexes
#
#  index_users_on_username_and_company_id  (username,company_id) UNIQUE
#  index_users_on_reset_password_token     (reset_password_token) UNIQUE
#  index_users_on_autologin                (autologin)
#  users_company_id_index                  (company_id)
#  index_users_on_customer_id              (customer_id)
#  index_users_on_last_seen_at             (last_seen_at)
#  users_uuid_index                        (uuid)
#

