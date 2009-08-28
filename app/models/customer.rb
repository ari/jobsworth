# A logical grouping of projects, called Client inside
# ClockingIT.

class Customer < ActiveRecord::Base
  has_many(:custom_attribute_values, :as => :attributable, :dependent => :destroy, 
           # set validate = false because validate method is over-ridden and does that for us
           :validate => false)
  include CustomAttributeMethods

  belongs_to    :company
  has_many      :projects, :order => "name", :dependent => :destroy
  has_many      :work_logs
  has_many      :project_files
  has_many      :users, :order => "lower(name)"
  has_many      :resources

  has_many :task_customers, :dependent => :destroy
  has_many :tasks, :through => :task_customers

  has_many      :organizational_units 

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
    return company.customers.find(:all, 
                                  :conditions => Search.search_conditions_for(strings))
  end

  ###
  # Returns true if this customer if the internal customer for
  # its company.
  ###
  def internal_customer?
    self == company.internal_customer
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
    if internal_customer?
      self.company.name
    else
      self.name
    end
  end

  def logo?
    File.exist?(self.logo_path)
  end

  def to_s
    full_name
  end
end
