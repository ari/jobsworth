###
# Properties are used to describe tasks. Each property has a number of 
# PropertyValues which define the values available for the user to choose
# from.
#
# Properties can be created and edited by users in the system and so can 
# have any PropertyValues a user needs.

# Examples of potential properties include Priority, Status, Sub-project
# - anything that suits a company's workflow..
###
class Property < ActiveRecord::Base
  belongs_to :company
  has_many :property_values, :order => "position asc, id asc", :dependent => :destroy


  ###
  # Returns all properties setup for company.
  ###
  def self.all_for_company(company)
    find(:all, :conditions => { :company_id => company.id })
  end

  ###
  # Returns an array of all properties for company which
  # have colors set up for their property values.
  ###
  def self.all_with_colors(company)
    props = all_for_company(company).select do |p|
      p.property_values.detect { |pv| !pv.color.blank? }
    end

    return props
  end

  ###
  # Returns an array of all properties for company which
  # have icons set up for their property values.
  ###
  def self.all_with_icons(company)
    props = all_for_company(company).select do |p|
      p.property_values.detect { |pv| !pv.icon_url.blank? }
    end

    return props
  end

  ###
  # Finds the property matching the given group_by parameter.
  ###
  def self.find_by_group_by(company, group_by)
    return if !group_by

    # N.B. This is mainly used in task filtering in the list view.
    match = group_by.match(/property_(\d+)/)
    return company.properties.find(match[1]) if match
  end

  ###
  # Returns a name suitable for use as a div id or similar.
  ###
  def filter_name
    @filter_name ||= "property_#{ id }"
  end

  def to_s
    name
  end
end
