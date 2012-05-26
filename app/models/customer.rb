# encoding: UTF-8
# A logical grouping of projects, called Client in the UI

class Customer < ActiveRecord::Base
  # Creates a score_rules association and updates the score
  # of all the task when adding a new score rule
  include Scorable

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
  has_many      :notes, :as => :notable, :class_name => "Page", :order => "id desc"

  has_many :task_customers, :dependent => :destroy
  has_many :tasks, :through => :task_customers

  has_many      :organizational_units
  has_many      :service_level_agreements, :include => :service, :dependent => :destroy, :order => "services.name ASC"
  has_many      :services, :through => :service_level_agreements, :order => "services.name ASC"

  validates_length_of           :name,  :maximum=>200
  validates_presence_of         :name

  validates_uniqueness_of       :name, :scope => 'company_id', :case_sensitive => false

  validates_presence_of         :company_id
  validate                      :validate_custom_attributes

  def self.from_company(company_id)
    where("customers.company_id = ?", company_id)   
  end

  def self.search_by_name(search_criteria)
    where('name LIKE ?', '%' + search_criteria + '%')
  end

  ###
  # Searches the customers for company and returns
  # any that have names or ids that match at least one of
  # the given strings
  ###
  def self.search(company, strings)
    conds = Search.search_conditions_for(strings, [ :name ], :start_search_only => true)
    return company.customers.where(conds)
  end

  ###
  # Returns true if this customer if the internal customer for
  # its company.
  ###
  def internal_customer?
    self == company.internal_customer
  end

  def has_projects?
    projects.count > 0
  end

  def full_name
    if internal_customer?
      self.company.name
    else
      self.name
    end
  end


  def to_s
    full_name
  end
end



# == Schema Information
#
# Table name: customers
#
#  id           :integer(4)      not null, primary key
#  company_id   :integer(4)      default(0), not null
#  name         :string(200)     default(""), not null
#  contact_name :string(200)
#  created_at   :datetime
#  updated_at   :datetime
#  active       :boolean(1)      default(TRUE)
#
# Indexes
#
#  customers_company_id_index  (company_id,name)
#

