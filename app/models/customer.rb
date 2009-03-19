# A logical grouping of projects, called Client inside
# ClockingIT.

class Customer < ActiveRecord::Base
  belongs_to    :company
  has_many      :projects, :order => "name", :dependent => :destroy
  has_many      :work_logs
  has_many      :project_files
  has_many      :users

  validates_length_of           :name,  :maximum=>200
  validates_presence_of         :name

  validates_uniqueness_of       :name, :scope => 'company_id'
  
  validates_presence_of         :company_id

  after_destroy { |r|
    File.delete(r.logo_path) rescue begin end
  }

  ###
  # Searches the customers for company and returns 
  # any that have names or ids that match at least one of
  # the given strings
  ###
  def self.search(company, strings)
    conds = []
    cond_params = []
    
    strings.each do |s|
      next if s.to_i <= 0
      conds << "id = ?"
      cond_params << s
    end
    
    strings.each do |s|
      conds << "lower(name) like ?"
      cond_params << "%#{ s.downcase.strip }%"
    end
    
    conds = [ conds.join(" or ") ] + cond_params
    return company.customers.find(:all, :conditions => conds)
  end

  def path
    File.join("#{RAILS_ROOT}", 'store', 'logos', self.company_id.to_s)
  end

  def store_name
    "logo_#{self.id}"
  end

  def logo_path
    File.join(self.path, self.store_name)
  end

  def full_name
    if self.name == 'Internal' || self.name == self.company.name
      self.company.name
    else
      self.name
    end
  end

  def logo?
    File.exist?(self.logo_path)
  end

end
