class User < ActiveRecord::Base

  require 'digest/md5'

  belongs_to    :company
  has_many      :projects, :through => :project_permissions
  has_many      :project_permissions, :dependent => :destroy
  has_many      :pages, :dependent => :nullify
  has_many      :tasks, :through => :task_owners
  has_many      :task_owners, :dependent => :destroy
  has_many      :work_logs, :dependent => :destroy
  has_many      :shouts, :dependent => :destroy

  has_many      :notifications, :dependent => :destroy
  has_many      :notifies, :through => :notifications, :source => :task

  has_many      :forums, :through => :moderatorships, :order => 'forums.name'

  has_many      :posts
  has_many      :topics
  has_many      :monitorships
  has_many      :monitored_topics, :through => :monitorships, :conditions => ['monitorships.active = ?', true], :order => 'topics.replied_at desc', :source => :topic

  has_many :moderatorships, :dependent => :destroy
  has_many :forums, :through => :moderatorships, :order => 'forums.name'


#  composed_of  :tz, :class_name => 'TZInfo::Timezone',
#               :mapping => %w(time_zone time_zone)

  validates_length_of           :name,  :maximum=>200
  validates_presence_of         :name

  validates_length_of           :username,  :maximum=>200
  validates_presence_of         :username
  validates_uniqueness_of       :username, :scope => "company_id"

  validates_length_of           :password,  :maximum=>200
  validates_presence_of         :password

  validates_length_of           :email,  :maximum=>200
  validates_presence_of         :email

  validates_presence_of         :company_id

  after_destroy { |r|
    begin
      File.delete(r.avatar_path)
      File.delete(r.avatar_large_path)
    rescue
    end
  }

  before_create                 :generate_uuid

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
      User.find( :first, :conditions => [ 'username = ? AND password = ?', self.username, self.password ] )
    end
  end

  def can?(project, perm)
    return if self.project_permissions.nil?
    self.project_permissions.each do | p |
        return p.can?(perm) if p.project_id == project.id
    end
    return false
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

end
