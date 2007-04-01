class Company < ActiveRecord::Base
  has_many      :customers, :dependent => :destroy
  has_many      :users, :dependent => :destroy
  has_many      :projects, :dependent => :destroy
  has_many      :tasks
  has_many      :pages
  has_many      :work_logs
  has_many      :activities, :dependent => :destroy
  has_many      :project_files, :dependent => :destroy
  has_many      :shouts, :dependent => :destroy

  has_many      :tags, :dependent => :destroy

#  validates_format_of :contact_email, :with => /^([^@\s]+)@((?:[-a-z0-9]+\.)+[a-z]{2,})$/
#  validates_length_of :contact_name,  :in=>3..200
  validates_length_of           :name,  :maximum=>200
  validates_presence_of         :name
  validates_presence_of         :subdomain
  validates_uniqueness_of       :subdomain


  def internal_customer
    customers.find(:first, :conditions => ["(name = ? OR name = 'Internal') AND company_id = ? ", self.name, self.id])
  end

end
