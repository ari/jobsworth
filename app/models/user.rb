class User < ActiveRecord::Base

  require_dependency 'digest/md5'

  belongs_to    :company
  has_many      :projects, :through => :project_permissions, :conditions => ['projects.completed_at IS NULL']
  has_many      :completed_projects, :through => :project_permissions, :conditions => ['projects.completed_at IS NOT NULL'], :source => :project
  has_many      :project_permissions, :dependent => :destroy
  has_many      :pages, :dependent => :nullify
  has_many      :tasks, :through => :task_owners
  has_many      :task_owners, :dependent => :destroy
  has_many      :work_logs, :dependent => :destroy
  has_many      :shouts, :dependent => :nullify

  has_many      :notifications, :dependent => :destroy
  has_many      :notifies, :through => :notifications, :source => :task

  has_many      :forums, :through => :moderatorships, :order => 'forums.name'
  has_many      :moderatorships, :dependent => :destroy

  has_many      :posts, :dependent => :destroy
  has_many      :topics, :dependent => :destroy

  has_many      :monitorships,:dependent => :destroy
  has_many      :monitored_topics, :through => :monitorships, :source => 'topic', :conditions => ['monitorships.active = ? AND monitorship_type = ?', true, 'topic'], :order => 'topics.replied_at desc'
  has_many      :monitored_forums, :through => :monitorships, :source => 'forum', :conditions => ['monitorships.active = ? AND monitorship_type = ?', true, 'forum'], :order => 'forums.position'

  has_many      :moderatorships, :dependent => :destroy
  has_many      :forums, :through => :moderatorships, :order => 'forums.name'

  has_many      :shout_channel_subscriptions, :dependent => :destroy
  has_many      :shout_channels, :through => :shout_channel_subscriptions, :source => :shout_channel

  has_many      :widgets, :order => "widgets.column, widgets.position", :dependent => :destroy

  validates_length_of           :name,  :maximum=>200, :allow_nil => true
  validates_presence_of         :name

  validates_length_of           :username,  :maximum=>200, :allow_nil => true
  validates_presence_of         :username
  validates_uniqueness_of       :username, :scope => "company_id"

  validates_length_of           :password,  :maximum=>200, :allow_nil => true
  validates_presence_of         :password

  validates_length_of           :email,  :maximum=>200, :allow_nil => true
  validates_presence_of         :email

  validates_presence_of         :company

  after_destroy { |r|
    begin
      File.delete(r.avatar_path)
      File.delete(r.avatar_large_path)
    rescue
    end
  }

  before_create                 :generate_uuid

  after_create			:generate_widgets
  
  attr_protected :admin, :uuid, :autologin

  def path
    File.join("#{RAILS_ROOT}", 'store', 'avatars', self.company_id.to_s)
  end

  def avatar_path
    File.join(self.path, "#{self.id}")
  end

  def avatar_large_path
    File.join(self.path, "#{self.id}_large")
  end

  def avatar?
    File.exist? self.avatar_path
  end

  def generate_uuid
    @attributes['uuid'] = Digest::MD5.hexdigest( rand(100000000).to_s + Time.now.to_s)
    @attributes['autologin'] = Digest::MD5.hexdigest( rand(100000000).to_s + Time.now.to_s)
  end

  def new_widget
    Widget.new(:user => self, :company_id => self.company_id, :collapsed => 0, :configured => true)
  end
  
  def generate_widgets
    w = new_widget
    w.name =  "Top Tasks"
    w.widget_type = 0
    w.number = 5
    w.mine = true
    w.order_by = "priority"
    w.column = 0
    w.position = 0
    w.save
    
    w = new_widget
    w.name =  "Newest Tasks"
    w.widget_type = 0
    w.number = 5
    w.mine = false
    w.order_by = "date"
    w.column = 0
    w.position = 1
    w.save
    
    w = new_widget
    w.name =  "Recent Activities"
    w.widget_type = 2
    w.number = 20
    w.column = 2
    w.position = 0
    w.save
    
    w = new_widget
    w.name =  "Open Tasks"
    w.widget_type = 3
    w.number = 7
    w.mine = true
    w.column = 1
    w.position = 0
    w.save
    
    w = new_widget
    w.name =  "Projects"
    w.widget_type = 1
    w.number = 0
    w.column = 1
    w.position = 1
    w.save
  end
  
  def avatar_url(size=32)
    if avatar?
      if size > 25
        "/users/avatar/#{self.id}?large=1"
      else
        "/users/avatar/#{self.id}"
      end
    else
      "http://www.gravatar.com/avatar.php?gravatar_id=#{Digest::MD5.hexdigest(self.email.downcase)}&rating=PG&size=#{size}"
    end
  end

  def display_name
    self.name
  end

  def login(subdomain = nil)
    unless (subdomain.nil? || ['www'].include?(subdomain))
      company = Company.find(:first, :conditions => ["subdomain = ?", subdomain.downcase])
      User.find( :first, :conditions => [ 'username = ? AND password = ? AND company_id = ?', self.username, self.password, company.id ] )
    else
      nil
    end
  end

  def can?(project, perm)
    return false if self.project_permissions.nil?
    self.project_permissions.each do | p |
        return p.can?(perm) if p.project_id == project.id
    end
    return false
  end

  def can_all?(projects, perm)
    projects.each do |p|
      return false unless self.can?(p, perm)
    end
    true
  end

  def can_any?(project, perm)
    projects.each do |p|
      return true if self.can?(p, perm)
    end
    false
  end
  
  def admin?
    self.admin > 0
  end

  def currently_online
    User.find(:all, :conditions => ["company_id = ? AND last_seen_at > ?", self.company, Time.now.utc-5.minutes])
  end

  def moderator_of?(forum)
    moderatorships.count(:all, :conditions => ['forum_id = ?', (forum.is_a?(Forum) ? forum.id : forum)]) == 1
  end

  def online?
    (!self.last_ping_at.nil? && self.last_ping_at > 3.minutes.ago.utc)
  end

  def online_status_name
    if self.last_ping_at.nil? || self.last_ping_at < 3.minutes.ago.utc
      return "<span class=\"status-offline\">#{self.name} (offline)</span>"
    elsif self.last_seen_at.nil? || self.last_seen_at < 10.minutes.ago.utc
      return "<span class=\"status-idle\">#{self.name} (idle)</span>"
    end
    "<span class=\"status-online\">#{self.name}</span>"
  end

  def tz
    unless @tz
      @tz = Timezone.get(self.time_zone)
    end
    @tz
  end


end
