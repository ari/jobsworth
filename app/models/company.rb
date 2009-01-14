# A logical grouping of all users sharing projects
#
# Author:: Erlend Simonsen (mailto:admin@clockingit.com)
#

class Company < ActiveRecord::Base
  has_many      :customers, :dependent => :destroy
  has_many      :users, :dependent => :destroy
  has_many      :projects, :dependent => :destroy, :order => 'name'
  has_many      :tasks
  has_many      :pages, :dependent => :destroy
  has_many      :work_logs
  has_many      :project_files, :dependent => :destroy
  has_many      :shout_channels, :dependent => :destroy
  has_many      :tags, :dependent => :destroy, :order => 'name'
  has_many      :properties


#  validates_format_of :contact_email, :with => /^([^@\s]+)@((?:[-a-z0-9]+\.)+[a-z]{2,})$/
#  validates_length_of :contact_name,  :in=>3..200
  validates_length_of           :name,  :maximum=>200
  validates_presence_of         :name
  validates_presence_of         :subdomain
  validates_uniqueness_of       :subdomain

  after_create :create_default_properties

  # Find the Internal client of this company.
  # A small kludge is needed,as it was previously called Internal, now it has the same
  # name as the parent company.
  def internal_customer
    customers.find(:first, :conditions => ["(name = ? OR name = 'Internal') AND company_id = ? ", self.name, self.id], :order => 'id')
  end

  ###
  # Creates the default properties used for describing tasks.
  # Returns an array of the created properties.
  ###
  def create_default_properties
    new_props = []
    Property.defaults.each do |property_params, property_values_params|
      p = properties.new(property_params)
      p.property_values.build(property_values_params)
      p.save!

      new_props << p
    end

    return new_props
  end

end
