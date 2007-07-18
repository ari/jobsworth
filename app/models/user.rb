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

  before_create                 :generate_uuid

  def generate_uuid
    @attributes['uuid'] = Digest::MD5.hexdigest( rand(100000000).to_s + Time.now.to_s)
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

end
