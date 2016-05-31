# encoding: UTF-8
# A logical grouping of all users sharing projects
#

class Company < ActiveRecord::Base
  # Creates a score_rules association and updates the score
  # of all the task when adding a new score rule
  include Scorable

  has_attached_file :logo, :whiny => false, :styles=>{ :original => "250x50>"},
                    :path => File.join(Setting.store_root, ":id", 'logos', "logo_:id_:style.:extension")

  validates_attachment_content_type :logo, content_type: /\Aimage/

  Paperclip.interpolates :id do |attachment, style|
    attachment.instance.id
  end

  has_many      :customers, -> { order("lower(customers.name)") }, :dependent => :destroy
  has_many      :users, :dependent => :destroy
  has_one       :admin, -> { where("admin = 1") }, :class_name => "User"
  has_many      :projects, -> { order("lower(projects.name)") }, :dependent => :destroy
  has_many      :milestones
  has_many      :tasks, :class_name => "TaskRecord"
  has_many      :templates
  has_many      :snippets, :dependent => :destroy
  has_many      :work_logs
  has_many      :project_files, :dependent => :destroy
  has_many      :tags, -> { order('tags.name') }, :dependent => :destroy
  has_many      :properties, -> { includes(:property_values) }, :dependent => :destroy
  has_many      :property_values, :through => :properties
  has_many      :resources, -> { order("lower(name)") }, :dependent => :destroy
  has_many      :resource_types, -> { order("lower(name)") }, :dependent => :destroy
  has_many      :custom_attributes, :dependent => :destroy
  has_many      :task_filters, :dependent => :destroy
  has_many      :statuses, -> { order("id asc") }, :dependent => :destroy
  has_many      :wiki_pages, :dependent => :destroy
  has_many      :triggers, :dependent => :destroy
  has_many      :services, :dependent => :destroy
  has_many      :service_level_agreements, :dependent => :destroy
  has_many      :news_items, :dependent => :destroy
  has_many      :email_addresses

  has_many      :preferences, :as => :preferencable
  include PreferenceMethods

#  validates_format_of :contact_email, :with => /^([^@\s]+)@((?:[-a-z0-9]+\.)+[a-z]{2,})$/
#  validates_length_of :contact_name,  :in=>3..200
  validates_length_of           :name,  :maximum=>200
  validates_presence_of         :name
  validates_presence_of         :subdomain
  validates_uniqueness_of       :subdomain

  after_create :create_default_properties
  after_create :create_default_statuses

  class << self

    # Return the first Company if there is only one company in database.
    # Handy in testing environemnts where Company can not be determined from subdomain
    def sole_company
      Company.first if not Company.many?
    end

  end

  ###
  # Creates the default properties used for describing tasks.
  # Returns an array of the created properties.
  ###
  def create_default_properties
    new_props = []
    Property.defaults.each do |property_params, property_values_params|
      name = property_params[:name]
      existing = properties.detect { |p| p.name == name }

      if !existing
        p = properties.new(property_params)
        p.property_values.build(property_values_params)
        p.save!
        new_props << p
      else
        new_props << existing
      end
    end

    self.properties.reload
    return new_props
  end

  # Creates the default statuses for this company
  def create_default_statuses
    Status.create_default_statuses(self)
  end

  def suppressed_emails
    self.suppressed_email_addresses.blank? ? [] : self.suppressed_email_addresses.split(/,|\n/).collect {|e| e.strip }
  end

  ###
  # Sorts the given tasks in the default sort order.
  # Default sorting uses the completed at time, the due date, task num and any
  # custom properties with the default_sort parameter.
  ###
  def sort(tasks)
    res = tasks.sort_by do |task|
      array = []
      array << -task.completed_at.to_i
      array << rank_by_properties(task)
      array << - (task.due_date || 9999999999).to_i
      array << - task.task_num
    end
    res = res.reverse

    return res
  end

  ###
  # Returns an array of properties that should be used for sorting tasks.
  ###
  def sort_properties
    properties.select { |p| p.default_sort }
  end

  ###
  # Returns the maximum sort rank a task could possibly have.
  ###
  def maximum_sort_rank
    @maximum_sort_rank ||= sort_properties.inject(0) { |rank, property| rank += property.property_values.length }
  end

  ###
  # Returns an int to to use to rank the task according to properties
  # set up as default_sort.
  ###
  def rank_by_properties(task)
    rank_by_properties = sort_properties.inject(0) do |rank, property|
      pv = task.property_value(property)
      rank ||= 0 # for some reason rank is nil occasionally in tests.

      if pv
        rank += (pv.sort_rank || 0)
      end
    end

    return (rank_by_properties || 0)
  end

  # Returns the property to use to represent a tasks type.
  def type_property
    @type_property ||= properties.detect { |p| p.name == "Type" || p.name == I18n.t("properties.type") }
  end

  ###
  # Returns the URL to the installation
  ###
  def site_URL
    if Setting.SSL
      url = "https://"
    else
      url = "http://"
    end
    url += subdomain + "." + Setting.domain
  end

  # Returns a list of property values which should be considered
  # as marking tasks as critical priority
  def critical_values
    @critical_values ||= sort_properties.inject([]) do |res, prop|
      range = (prop.property_values.count / 3).to_i
      res += prop.property_values[0, range]
    end
  end

  # Returns a list of property values which should be considered
  # as marking tasks as normal priority
  def normal_values
    @normal_values ||= sort_properties.inject([]) do |res, prop|
      res += prop.property_values.select do |pv|
        !critical_values.index(pv) and !low_values.index(pv)
      end
    end
  end

  # Returns a list of property values which should be considered
  # as marking tasks as low priority
  def low_values
    @low_values ||= sort_properties.inject([]) do |res, prop|
      length = prop.property_values.count
      range = length - (length / 3).to_i
      res += prop.property_values[range, length]
    end
  end

  # Find the Internal client of this company.
  # A small kludge is needed,as it was previously called Internal, now it has the same
  # name as the parent company.
  def internal_customer
    conds = ["(name = ? OR name = 'Internal') AND company_id = ? ", self.name, self.id]
    @internal_customer ||= customers.where(conds).order('id').first
  end

  def logo_path
    logo.path
  end

  def logo?
    !self.logo_path.nil? && File.exist?(self.logo_path)
  end

end




# == Schema Information
#
# Table name: companies
#
#  id                         :integer(4)      not null, primary key
#  name                       :string(200)     default(""), not null
#  contact_email              :string(200)
#  contact_name               :string(200)
#  created_at                 :datetime
#  updated_at                 :datetime
#  subdomain                  :string(255)     default(""), not null
#  show_wiki                  :boolean(1)      default(TRUE)
#  suppressed_email_addresses :text
#  logo_file_name             :string(255)
#  logo_content_type          :string(255)
#  logo_file_size             :integer(4)
#  logo_updated_at            :datetime
#
# Indexes
#
#  index_companies_on_subdomain  (subdomain) UNIQUE
#

